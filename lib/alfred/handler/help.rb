require 'alfred/handler'

module Alfred
  module Handler

    class Help < Base
      def initialize(alfred, opts = {})
        super
        @order = 9
        @settings = {
          :exclusive? => true   ,
          :handler    => 'Help'
        }.update(opts)

        unless @settings[:items]
          @settings[:items] = alfred.workflow_setting[:help]
        end

      end

      def on_parser
        parser.on('-h', '--help', 'Workflow Helper') do
          options.help = true
        end
      end

      def on_help
        {
          :kind     => 'text'                        ,
          :title    => '-h, --help [query]'          ,
          :subtitle => 'Print workflow help message' ,
        }
      end

      def feedback?
        options.help
      end

      def on_feedback
        return unless feedback?

        @settings[:items].each do |item|

          case item[:kind]
          when 'file'
            item[:path] = File.expand_path(item[:path])
            item[:arg] = xml_builder(
              :handler => @settings[:handler] ,
              :kind    => item[:kind]         ,
              :path    => item[:path]
            )

            feedback.add_file_item(item[:path], item)

          when 'url'
            item[:arg] = xml_builder(
              :handler => @settings[:handler] ,
              :kind    => item[:kind]         ,
              :url     => item[:url]
            )

            feedback.add_item(
              {
                :icon => feedback.CoreServicesIcon('BookmarkIcon')
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
                :icon         => feedback.CoreServicesIcon('ClippingText') ,
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
                :icon => feedback.CoreServicesIcon('HelpIcon'),
              }.merge(item)
            )
          end
        end

        @status = :exclusive if @settings[:exclusive?]
      end

      def action?(arg)
        arg.is_a?(Hash) && arg[:handler].eql?(@settings[:handler])
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
