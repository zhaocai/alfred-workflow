require "rexml/document"
require 'alfred/feedback/item'
require 'alfred/feedback/file_item'
require 'alfred/feedback/webloc_item'

module Alfred

  class Feedback
    attr_accessor :items
    attr_reader :backend_file

    def initialize(alfred, opts = {}, &blk)
      @items = []
      @core = alfred
      use_backend(opts)
      instance_eval(&blk) if block_given?
    end

    def add_item(opts = {})
      raise ArgumentError, "Feedback item must have title!" if opts[:title].nil?
      @items << Item.new(opts[:title], opts)
    end

    def add_file_item(path, opts = {})
      @items << FileItem.new(path, opts)
    end

    def add_webloc_item(path, opts = {})
      unless opts[:folder]
        opts[:folder] = @core.storage_path
      end
      @items << WeblocItem.new(path, opts)
    end

    def to_xml(with_query = '', items = @items)
      document = REXML::Element.new("items")
      if with_query.empty?
        items.each do |item|
          document << item.to_xml
        end
      else
        items.each do |item|
          document << item.to_xml if item.match?(with_query)
        end
      end
      document.to_s
    end

    alias_method :to_alfred, :to_xml

    #
    # Merge with other feedback
    #
    def merge!(other)
      @items |= other.items
    end

    #
    # The workflow is about to complete
    #
    # - save cached feedback if necessary
    # 
    def close
      put_cached_feedback if @backend_file
    end

    #
    # ## helper class method for icon
    #
    def self.CoreServicesIcon(name)
      {
        :type => "default" ,
        :name => "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/#{name}.icns"
      }
    end

    def self.Icon(name)
      {
        :type => "default" ,
        :name => name       ,
      }
    end
    def self.FileIcon(path)
      {
        :type => "fileicon" ,
        :name => path       ,
      }
    end


    #
    # ## serialization
    #
    def use_backend(opts = {})
      @backend_file = opts[:file] if opts[:file]
      @should_expire_after_second = opts[:expire].to_i if opts[:expire]
    end
    alias_method :use_cache_file, :use_backend

    def backend_file
      @backend_file ||= File.join(@core.volatile_storage_path, "cached_feedback")
    end

    def expired?
      return false unless @should_expire_after_second
      Time.now - File.ctime(backend_file) > @should_expire_after_second
    end

    def get_cached_feedback
      return nil unless File.exist?(backend_file)
      return nil if expired?

      load(@backend_file)
      self
    end

    def put_cached_feedback
      dump(backend_file)
    end

    def dump(to_file)
      File.open(to_file, "wb") { |f| Marshal.dump(@items, f) }
    end

    def load(from_file)
      @items = File.open(from_file, "rb") { |f| Marshal.load(f) }
    end

    def append(from_file)
      @items << File.open(from_file, "rb") { |f| Marshal.load(f) }
    end

  end

end
