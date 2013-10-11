require 'alfred/handler/help'

module Alfred::Handler

  class HandlerHelp < Help
    def initialize(alfred, opts = {})
      opts[:items] = []
      super
      @settings[:exclusive?] = false
      @core.handler_controller.each do |h|
        @settings[:items] << h.on_help
      end
      @order -= 1
    end

    def on_help
      []
    end

  end

end
