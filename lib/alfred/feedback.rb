require "rexml/document"

module Alfred

  class Feedback
    attr_accessor :items

    class Item
      attr_accessor :uid, :arg, :valid, :autocomplete, :title, :subtitle, :icon

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

    class FileItem < Item

      def initialize(path)
        if ['.ennote', '.webbookmark'].include? File.extname(path)
          @title = %x{mdls -name kMDItemDisplayName -raw '#{path}'}
        else
          @title = File.basename(path)
        end
        @subtitle = path
        @uid = path
        @arg = path
        @icon = {:type => "fileicon", :name => path}
        @valid = 'yes'
        @autocomplete = @title
        @type = 'file'
      end

      def match?(query)
        return true if query.empty?
        if query.is_a? String
          query = query.split("\s")
        end

        queries = []
        query.each { |q|
          queries << smart_query(q)
        }

        queries.delete_if { |q|
          q.match(@title) or q.match(@subtitle)
        }

        if queries.empty?
          return true
        else
          return false
        end
      end

    end


    def initialize
      @items = []
    end

    def add_item(opts = {})
      raise ArgumentError, "Feedback item must have title!" if opts[:title].nil?
      @items << Item.new(opts[:title], opts)
    end

    def add_file_item(path)
      @items << FileItem.new(path)
    end


    def output_for_query(query = '', items = @items)
      puts to_xml(query, items)
    end

    def to_xml(query = '', items = @items)
      document = REXML::Element.new("items")
      items.each do |item|
        document << item.to_xml if item.match?(query)
      end
      document.to_s
    end

  end

end
