require 'alfred/handler'

module Alfred
  module Handler

    class Help < Base
      def initialize(alfred, opts = {})
        super
        @order = 9
        @settings = {
          :handler                    => 'Help' ,
          :exclusive?                 => true   ,
          :with_handler_help          => false  ,
          :items                      => []     ,
        }.update(opts)
        if @settings[:items].empty?
          @load_from_workflow_setting = true
        else
          @load_from_workflow_setting = false
        end

      end

      def on_parser
        parser.on_tail('-?', '-h', '--help', 'Workflow Helper') do
          options.help = true
        end
      end

      def on_help
        {
          :kind     => 'text'                     ,
          :title    => '-?, -h, --help [query]'   ,
          :subtitle => 'Show Workflow Usage Help' ,
        }
      end

      def feedback?
        options.help
      end

      def on_feedback
        return unless feedback?


        if @settings[:with_handler_help]
          @core.handler_controller.each do |h|
            @settings[:items].push h.on_help
          end
        end

        if @load_from_workflow_setting
          if @core.workflow_setting.has_key?(:help)
            @settings[:items].push @core.workflow_setting[:help]
          end
        end

        @settings[:items].flatten!

        @settings[:items].each do |item|

          case item[:kind]
          when 'file'
            item[:path] = File.expand_path(item[:path])
            # action is handled by fallback action in the main loop
            feedback.add_file_item(item[:path], item)
          when 'url'
            item[:arg] = xml_builder(
              :handler => @settings[:handler] ,
              :kind    => item[:kind]         ,
              :url     => item[:url]
            )

            feedback.add_item(
              {
                :icon => ::Alfred::Feedback.CoreServicesIcon('BookmarkIcon')
              }.merge(item)
            )

          when 'text', 'message'
            item[:arg] = xml_builder(
              {
                :handler      => @settings[:handler] ,
                :kind         => item[:kind]         ,
              }
            )

            feedback.add_item(
              {
                :valid        => 'no' ,
                :autocomplete => ''   ,
                :icon         => ::Alfred::Feedback.CoreServicesIcon('ClippingText') ,
              }.merge(item)
            )

          else
            item[:arg] = xml_builder(
              {
              :handler => @settings[:handler] ,
              :kind    => item[:kind]         ,
              }.merge(item)
            )

            feedback.add_item(
              {
                :icon => ::Alfred::Feedback.CoreServicesIcon('HelpIcon'),
              }.merge(item)
            )
          end
        end

        @status = :exclusive if @settings[:exclusive?]
      end


      def on_action(arg)
        return unless action?(arg)

        case arg[:kind]
        when 'url'
          ::Alfred::Util.open_url(arg[:url])
        when 'file'
          %x{open "#{arg[:path]}"}
        end
      end
    end

  end
end
