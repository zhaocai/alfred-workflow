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

    def to_xml(items = @items)
      document = REXML::Element.new("items")
      items.each do |item|
        document << item.to_xml
      end
      document.to_s
    end

  end

end
