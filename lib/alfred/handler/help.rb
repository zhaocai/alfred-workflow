require 'alfred/handler'

module Alfred
  module Handler

    class Help < Base
      def initialize(alfred, opts = {})
        super
        @order = 9
        @settings = {
          :setting => alfred.workflow_setting,
          :key => :help,
        }.update(opts)

      end

      def on_parser
        query_parser.on_tail('-h', '--help', 'Workflow Helper') do
          options.help = true
        end
      end

      def on_feedback
        return unless options.help

        @status = :exclusive

        feedback_items = @settings[:setting][@settings[:key]]
        return if feedback_items.nil?

        feedback_items.each do |item|
          case item[:kind]
          when 'url'
            item[:folder] = storage_path
            Feedback::UrlItem.new(item)
          end
        end
      end

      def on_action
        raise NotImplementedError
      end
    end

  end
end
