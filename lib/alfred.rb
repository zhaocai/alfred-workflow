require 'rubygems' unless defined? Gem # rubygems is only needed in 1.8

require 'plist'
require 'fileutils'
require 'logging'
require "rexml/document"

require 'alfred/version'

module Alfred

  class AlfredError < RuntimeError
    def self.status_code(code)
      define_method(:status_code) { code }
    end
  end

  class ObjCError           < AlfredError; status_code(1) ; end
  class NoBundleIDError     < AlfredError; status_code(2) ; end
  class NoMethodError       < AlfredError; status_code(13) ; end
  class PathError           < AlfredError; status_code(14) ; end

  class << self

    def with_friendly_error(alfred = Alfred::Core.new, &blk)
      begin
        yield alfred
      rescue AlfredError => e
        alfred.ui.error e.message
        alfred.ui.debug e.backtrace.join("\n")
        exit e.status_code
      rescue Interrupt => e
        alfred.ui.error "\nQuitting..."
        alfred.ui.debug e.backtrace.join("\n")
        exit 1
      rescue SystemExit => e
        exit e.status
      rescue Exception => e
        alfred.ui.error(
          "Unfortunately, a fatal error has occurred. Please seek help in the Alfred Forum or raise an issue in \n" \
          "github. Thanks!\n  #{e.inspect} #{e.backtrace.join("\n")}\n")
        raise e
      end
    end
  end


  class Core
    attr_reader :query

    def initialize
    end

    def ui
      raise NoBundleIDError unless bundle_id
      @ui ||= Logger.new(bundle_id)
    end

    def feedback
      raise NoBundleIDError unless bundle_id
      @feedback ||= Feedback.new
    end

    def info_plist
      @info_plist ||= Plist::parse_xml('info.plist')
    end

    # Returns nil if not set.
    def bundle_id
      info_plist['bundleid'] unless info_plist['bundleid'].empty?
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

  end






  class Logger
    def initialize(id)
      @id = id
    end

    def info(msg)
      logger.info msg
    end
    def warn(msg)
      logger.warn msg
    end
    def debug(msg)
      logger.debug msg
    end
    def error(msg)
      logger.error msg
    end
    def fatal(msg)
      logger.fatal msg
    end

    def logger
      @logger ||= init_log
    end

    private

    def init_log
      @logger = Logging.logger[@id]
      logger_file = File.expand_path("~/Library/Logs/Alfred-Workflow.log")
      @logger.level = :debug
      @logger.add_appenders(
        Logging.appenders.file(logger_file)
      )
      @logger
    end
  end






  class Feedback
    attr_accessor :items

    def initialize
      @items = []
    end

    def add_item(opts = {})
      opts[:subtitle] ||= ""
      opts[:icon] ||= {:type => "default", :name => "icon.png"}
      if opts[:uid].nil?
        opts[:uid] = ''
      end
      opts[:arg] ||= opts[:title]
      opts[:valid] ||= "yes"
      opts[:autocomplete] ||= opts[:title]
      opts[:type] ||= "default"

      @items << opts unless opts[:title].nil?
    end

    def add_file_item(path)
      item = {}
      if ['.ennote', '.webbookmark'].include? File.extname(path)
        item[:title] = %x{mdls -name kMDItemDisplayName -raw '#{path}'}
      else
        item[:title] = File.basename(path)
      end
      item[:subtitle] = path
      item[:uid] = path
      item[:arg] = path
      item[:icon] = {:type => "fileicon", :name => path}
      item[:valid] = 'yes'
      item[:autocomplete] = item[:title]
      item[:type] = 'file'

      @items << item
    end


    def to_xml(items = @items)
      document = REXML::Element.new("items")
      items.each do |item|
        new_item = REXML::Element.new('item')
        new_item.add_attributes({
          'uid'          => item[:uid],
          'arg'          => item[:arg],
          'valid'        => item[:valid],
          'autocomplete' => item[:autocomplete]
        })
        new_item.add_attributes('type' => 'file') if item[:type] == "file"

        REXML::Element.new("title", new_item).text    = item[:title]
        REXML::Element.new("subtitle", new_item).text = item[:subtitle]

        icon = REXML::Element.new("icon", new_item)
        icon.text = item[:icon][:name]
        icon.add_attributes('type' => 'fileicon') if item[:icon][:type] == "fileicon"

        document << new_item
      end

      document.to_s
    end
  end





end

