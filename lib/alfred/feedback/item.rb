require "rexml/document"

module Alfred
  class Feedback
    class Item
      attr_accessor :uid, :arg, :valid, :autocomplete, :title, :subtitle, :icon, :type

      def initialize(title, opts = {})
        @title    = title
        @subtitle = opts[:subtitle] if opts[:subtitle]

        if opts[:icon]
          @icon    = opts[:icon]
        else
          @icon    = {:type => "default", :name => "icon.png"}
        end

        @uid      = opts[:uid] if opts[:uid]

        if opts[:arg]
          @arg    = opts[:arg]
        else
          @arg    = @title
        end

        if opts[:type]
          @type    = opts[:type]
        else
          @type    = 'default'
        end

        if opts[:valid]
          @valid    = opts[:valid]
        else
          @valid    = 'yes'
        end

        if opts[:autocomplete]
          @autocomplete    = opts[:autocomplete]
        else
          @autocomplete    = @title
        end
      end

      ## To customize a new match? function, overwrite it.
      #
      # Module Alfred
      #   class Feedback
      #     class Item
      #       alias_method :default_match?, :match?
      #       def match?(query)
      #         # define new match? function here
      #       end
      #     end
      #   end
      # end
      def match?(query)
        return true if query.empty?
        if smart_query(query).match(@title)
          return true
        else
          return false
        end
      end

      def to_xml
        xml_element = REXML::Element.new('item')
        xml_element.add_attributes({
          'uid'          => @uid,
          'arg'          => @arg,
          'valid'        => @valid,
          'autocomplete' => @autocomplete
        })
        xml_element.add_attributes('type' => 'file') if @type == "file"

        REXML::Element.new("title", xml_element).text    = @title
        REXML::Element.new("subtitle", xml_element).text = @subtitle

        icon = REXML::Element.new("icon", xml_element)
        icon.text = @icon[:name]
        icon.add_attributes('type' => 'fileicon') if @icon[:type] == "fileicon"

        xml_element
      end

      protected

      def smart_query(query)
        if query.is_a? Array
          query = query.join(" ")
        end
        option = Regexp::IGNORECASE
        if /[[:upper:]]/.match(query)
          option = nil
        end
        Regexp.compile(".*#{query.gsub(/\s+/,'.*')}.*", option)
      end

    end
  end
end
