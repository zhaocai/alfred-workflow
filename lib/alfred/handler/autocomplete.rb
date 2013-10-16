require 'alfred/handler'
require 'fuzzy_match'
require 'amatch'
FuzzyMatch.engine = :amatch

module Alfred
  module Handler

    class Autocomplete < Base
      def initialize(alfred, opts = {})
        super
        @order = 1000
        @settings = {
          :handler        => 'Autocomplete' ,
          :items          => {}             ,
          :fuzzy_score    => 0.5            ,
        }.update(opts)

        if @settings[:items].empty?
          @load_from_workflow_setting = true
        else
          @load_from_workflow_setting = false
        end
      end


      def add_fuzzy_match_feedback(items, before, query, base_item, to_feedback)
        return unless items

        matcher = FuzzyMatch.new(items)
        matcher.find_all_with_score(query).each do |item, dice_similar, leven_similar|
          next if item.size < query.size

          if (item.start_with?(query) or
              dice_similar > @settings[:fuzzy_score] or
              leven_similar > @settings[:fuzzy_score])

            to_feedback.add_item( base_item.merge(
              :title        => item,
              :autocomplete => "#{(before.dup.push item).join(' ')} "
            ))
          end
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

          add_fuzzy_match_feedback(@settings[:items][option],
                                   before, tail, base_item, feedback)
        end

      end


    end
  end
end
