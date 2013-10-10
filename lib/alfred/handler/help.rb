require 'alfred/handler'

module Alfred
  module Handler

    class Help < Base
      def initialize(alfred, opts = {})
        super
        @order = 9
        @settings = {
          :setting    => alfred.workflow_setting ,
          :key        => :help                   ,
          :exclusive? => true                    ,
        }.update(opts)

      end

      def on_parser
        parser.on('-h', '--help', 'Workflow Helper') do
          options.help = true
        end
      end

      def feedback?
        options.help
      end

      def on_feedback
        return unless feedback?

        feedback_items = @settings[:setting][@settings[:key]]
        return if feedback_items.nil?

        feedback_items.each do |item|

          base_arg = {
            :handler => 'Help'       ,
            :kind    => item[:kind]  ,
          }

          case item[:kind]
          when 'file'
            item[:path] = File.expand_path(item[:path])
            feedback.add_file_item(item[:path], item)
          when 'url'
            item[:arg] = xml_builder(
              base_arg.merge(:url => item[:url])
            )
            item[:icon] = @core.CoreServicesIcon('BookmarkIcon') unless item[:icon]
            feedback.add_item(item)
          else
            item[:arg] = xml_builder(
              base_arg.merge(:title => item[:title])
            )
            item[:icon] = @core.CoreServicesIcon('HelpIcon') unless item[:icon]
            feedback.add_item(item)
          end
        end

        @status = :exclusive if @settings[:exclusive?]
      end

      def action?(arg)
        arg.is_a?(Hash) && arg[:handler].eql?('Help')
      end

      def on_action(arg)
        return unless action?(arg)

        case arg[:kind]
        when 'url'
          ::Alfred::Util.open_url(arg[:url])
        end
      end
    end

  end
end
