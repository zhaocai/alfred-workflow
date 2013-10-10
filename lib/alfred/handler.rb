require 'alfred/util'

require 'set'
require "rexml/document"

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



      # from alfred core
      def xml_builder(arg)
        @core.xml_builder(arg)
      end

      def options
        @core.options
      end

      def parser
        @core.query_parser
      end

      def query
        @core.query
      end

      def feedback
        @core.feedback
      end
    end


    class Controller
      ## handlers are called based on handler.order
      # 1-10 : critical handler
      # 100  : base order

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
