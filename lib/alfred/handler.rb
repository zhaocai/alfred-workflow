require 'set'

module Alfred

  module Handler
    class Base
      attr_reader :status, :order

      def initialize(alfred, opts = {})
        @core = alfred
        @order = 100
        @status = :initialize
      end


      def on_parser
        ;
      end

      def on_feedback
        raise NotImplementedError
      end

      def on_action
        ;
      end

      def register
        @core.handler_controller.register(self)
      end

      def <=>(other)
        order <=> other.order
      end

      private

      def options
        @core.options
      end

      def query_parser
        @core.query_parser
      end

      def feedback
        @core.feedback
      end
    end


    class Controller
      ## handlers are called based on #order
      # 1-10: critical handler
      # 100:   base order

      include Enumerable

      def initialize
        @handlers = SortedSet.new
        @status = {:break => [:break, :exclusive]}
      end

      def register(handler)
        raise InvalidArgument unless handler.is_a? ::Alfred::Handler::Base
        @handlers.add(handler)
      end

      def each
        return enum_for(__method__) unless block_given?

        @handlers.each do |h|
          yield(h)
          break if @status[:break].include?(h.status)
        end
      end

      alias_method :each_handler, :each

    end
  end
end
