require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require 'plist'
require 'fileutils'
require 'yaml'
require 'optparse'
require 'ostruct'
require 'gyoku'
require 'nori'

require 'alfred/ui'
require 'alfred/feedback'
require 'alfred/setting'
require 'alfred/handler/handler_help'

module Alfred

  class AlfredError < RuntimeError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class ObjCError           < AlfredError; status_code(1) ; end
  class NoBundleIDError     < AlfredError; status_code(2) ; end
  class InvalidArgument     < AlfredError; status_code(10) ; end
  class InvalidFormat       < AlfredError; status_code(11) ; end
  class NoMethodError       < AlfredError; status_code(13) ; end
  class PathError           < AlfredError; status_code(14) ; end

  class << self

    def with_friendly_error(alfred = Alfred::Core.new, &blk)
      begin

        yield alfred
        alfred.start

      rescue AlfredError => e
        alfred.ui.error e.message
        alfred.ui.debug e.backtrace.join("\n")
        puts alfred.rescue_feedback(
          :title => "#{e.class}: #{e.message}") if alfred.with_rescue_feedback
        exit e.status_code
      rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
        alfred.ui.error e.message
        alfred.ui.debug $!.to_s
        alfred.ui.debug alfred.query_parser

        exit e.status
      rescue Interrupt => e
        alfred.ui.error "\nQuitting..."
        alfred.ui.debug e.backtrace.join("\n")
        puts alfred.rescue_feedback(
          :title => "Interrupt: #{e.message}") if alfred.with_rescue_feedback
        exit 1
      rescue SystemExit => e
        puts alfred.rescue_feedback(
          :title => "SystemExit: #{e.status}") if alfred.with_rescue_feedback
        exit e.status
      rescue Exception => e
        alfred.ui.error(
          "A fatal error has occurred. " \
          "You may seek help in the Alfred supporting site, "\
          "forum or raise an issue in the bug tracking site.\n" \
          "  #{e.inspect}\n  #{e.backtrace.join("  \n")}\n")
        puts alfred.rescue_feedback(
          :title => "Fatal Error!") if alfred.with_rescue_feedback
        exit(-1)
      end
    end

    def workflow_folder
      Dir.pwd
    end

    # launch alfred with query
    def search(query = "")
      %x{osascript <<__APPLESCRIPT__
      tell application "Alfred 2"
        search "#{query.gsub('"','\"')}"
      end tell
__APPLESCRIPT__}
    end

    def front_appname
      %x{osascript <<__APPLESCRIPT__
      name of application (path to frontmost application as text)
__APPLESCRIPT__}.chop
    end

    def front_appid
      %x{osascript <<__APPLESCRIPT__
      id of application (path to frontmost application as text)
__APPLESCRIPT__}.chop
    end

  end

  class Core
    attr_accessor :with_rescue_feedback
    attr_accessor :with_help_feedback

    attr_reader :handler_controller
    attr_reader :query


    def initialize(with_help_feedback = false,
                   with_rescue_feedback = true,
                   &blk)
      @workflow_dir = Dir.pwd
      @with_rescue_feedback = with_rescue_feedback
      @with_help_feedback = with_rescue_feedback

      @handler_controller = ::Alfred::Handler::Controller.new

      instance_eval(&blk) if block_given?
    end


    def start
      # step 1: register option parser for handlers
      @handler_controller.each_handler do |handler|
        handler.on_parser
      end
      query_parser.parse!
      @query = ARGV

      # step 2: dispatch options to handler for feedback or action
      case options.mode
      when :feedback
        if @with_help_feedback
          ::Alfred::Handler::HandlerHelp.new(self).register
        end
        @handler_controller.each_handler do |handler|
          handler.on_feedback
        end

        puts feedback.to_alfred(@query)
      when :action
        arg = @query
        if @query.length == 1
          if hsh = xml_parser(@query[0])
            arg = hsh
          end
        end

        @handler_controller.each_handler do |handler|
          handler.on_action(arg)
        end
      else
        raise InvalidArgument, "#{options.mode} mode is not supported."
      end

    end

    def options
      @options ||= OpenStruct.new
    end

    def query_parser
      @query_parser ||= init_query_parser
    end

    def xml_parser(xml)
      @xml_parser ||= Nori.new(:parser => :rexml,
                               :convert_tags_to => lambda { |tag| tag.to_sym })
      begin
        hsh = @xml_parser.parse(xml)
        return hsh[:root]
      rescue REXML::ParseException, Nokogiri::XML::SyntaxError
        return nil
      end
    end

    def xml_builder(arg)
      Gyoku.xml(:root => arg)
    end

    def ui
      raise NoBundleIDError unless bundle_id
      @ui ||= LogUI.new(bundle_id)
    end

    def setting(&blk)
      @setting ||= Setting.new(self, &blk)
    end

    def workflow_setting(opts = {})
      @workflow_setting ||= init_workflow_setting(opts)
    end

    def with_cached_feedback(&blk)
      @feedback = CachedFeedback.new(self, &blk)
    end

    def feedback(&blk)
      raise NoBundleIDError unless bundle_id
      @feedback ||= Feedback.new(self, &blk)
    end

    def info_plist
      @info_plist ||= Plist::parse_xml('info.plist')
    end

    # Returns nil if not set.
    def bundle_id
      @bundle_id ||= info_plist['bundleid'] unless info_plist['bundleid'].empty?
    end

    def volatile_storage_path
      raise NoBundleIDError unless bundle_id
      path = "#{ENV['HOME']}/Library/Caches/com.runningwithcrayons.Alfred-2/Workflow Data/#{bundle_id}"
      unless File.exist?(path)
        FileUtils.mkdir_p(path)
      end
      path
    end

    # Non-volatile storage directory for this bundle
    def storage_path
      raise NoBundleIDError unless bundle_id
      path = "#{ENV['HOME']}/Library/Application Support/Alfred 2/Workflow Data/#{bundle_id}"
      unless File.exist?(path)
        FileUtils.mkdir_p(path)
      end
      path
    end




    def rescue_feedback(opts = {})
      default_opts = {
        :title    => "Failed Query!",
        :subtitle => "Check the log file below for extra debug info.",
        :uid      => 'Rescue Feedback',
        :icon     => CoreServicesIcon('AlertStopIcon')
      }
      opts = default_opts.update(opts)

      items = []
      items << Feedback::Item.new(opts[:title], opts)
      items << Feedback::FileItem.new(ui.log_file)

      feedback.to_alfred('', items)
    end


    private

    def init_workflow_setting(opts)
      default_opts = {
        :file    => File.join(Alfred.workflow_folder, "setting.yaml"),
        :format  => 'yaml',
      }
      opts = default_opts.update(opts)

      Setting.new(self) do
        @backend_file = opts[:file]
        @formt = opts[:format]
      end
    end


    def init_query_parser
      options.mode = :feedback
      modifiers = [:comand, :alt, :control, :shift, :fn]
      OptionParser.new do |opts|
        opts.separator ""
        opts.separator "Built-in Options:"

        opts.on("--mode [TYPE]", [:feedback, :action],
                "Alfred handler working mode (feedback, action)") do |t|
          options.mode = t
        end

        opts.on("--modifier [MODIFIER]", modifiers,
                "Alfred action modifier (#{modifiers})") do |t|
          options.modifier = t
        end

        opts.separator ""
        opts.separator "Handler Options:"
      end

    end
  end
end

