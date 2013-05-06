require "alfred/feedback/file_item"
require 'alfred/util'

module Alfred
  class Feedback
    class WeblocItem < FileItem

      def initialize(title, opts = {})
        unless File.exist? opts[:webloc]
          opts[:webloc] = ::Alfred::Util.make_webloc(
            opts[:title], opts[:url], File.dirname(opts[:webloc]))
        end
        super opts[:webloc], opts

        @title = title if title
        @subtitle = opts[:url]
        @uid = opts[:url]
      end

    end
  end
end

