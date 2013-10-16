require 'alfred/handler'

module Alfred
  module Handler

    class Autocomplete < Base
      def initialize(alfred, opts = {})
        super
        @settings = {
          :handler           => 'Autocomplete' ,
          :items             => {}     ,
        }.update(opts)

        if @settings[:items].empty?
          @load_from_workflow_setting = true
        else
          @load_from_workflow_setting = false
        end
      end




      def on_feedback
        if @load_from_workflow_setting
          @settings[:items].update @core.workflow_setting[:autocomplete]
        end

        before, option, tail = @core.last_option

        base_item ={
          :match?   => :always_match?      ,
          :subtitle => "↩ to autocomplete" ,
          :valid    => 'no'                ,
          :icon     => ::Alfred::Feedback.CoreServicesIcon('ForwardArrowIcon') ,
        }

        if @settings[:items].has_key? tail
          @settings[:items][tail].each do |item|
            feedback.add_item( base_item.merge(
              :title        => item,
              :autocomplete => "#{(before.push [tail, item]).join(' ')} "
            ))
          end
        else
          @settings[:items][option].each do |item|
            if item.start_with?(tail) and !item.eql?(tail)
              feedback.add_item( base_item.merge(
                :title        => item,
                :autocomplete => "#{(before.push item).join(' ')} "
              ))
            end
          end
        end

      end


    end
  end
end
