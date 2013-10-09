require 'yaml'
require 'plist'

module Alfred

  class Setting
    attr_accessor :settings

    def initialize(alfred, &blk)
      @core = alfred
      instance_eval(&blk) if block_given?
      raise InvalidFormat, "#{format} is not suported." unless validate_format
      @backend = get_format_class(format).new(@core, setting_file)
    end

    def use_setting_file(opts = {})
      @setting_file = opts[:file] if opts[:file]
      @format = opts[:format] ? opts[:format] : "yaml"
    end


    def validate_format
      ['yaml', 'plist'].include?(format)
    end

    def format
      @format ||= "yaml"
    end

    def setting_file
      @setting_file ||= File.join(@core.storage_path, "setting.#{@format}")
    end

    def get_format_class(format_class)
      Alfred::Setting.const_get("#{format.to_s.capitalize}End")
    end

    def load
      @backend.send(:load)
    end

    def dump(object, opts = {})
      @backend.send(:dump, object, opts)
    end



    class BackEnd
      def initialize(alfred, file)
        @core = alfred
        @backend_file = file

        unless File.exist?(@backend_file)
          settings = {:id => @core.bundle_id}
          dump(settings, :flush => true)
        end
      end

      def load
        raise NotImplementedError
      end

      def dump(object, opts = {})
        raise NotImplementedError
      end
    end

    class YamlEnd < BackEnd
      def initialize(alfred, file)
        super
      end

      def load
        YAML::load_file(@backend_file)
      end

      def dump(object, opts = {})
        File.open(@backend_file, File::WRONLY|File::TRUNC|File::CREAT) { |f|
          YAML::dump(object, f)
          f.flush if opts[:flush]
        }
      end
    end

    class PlistEnd < BackEnd
      def initialize(alfred, file)
        super
      end

      def load
        Plist::parse_xml( File.read(@backend_file) )
      end

      def dump(object, opts = {})
        File.open(@backend_file, File::WRONLY|File::TRUNC|File::CREAT) { |f|
          f.puts object.to_plist
          f.flush if opts[:flush]
        }
      end
    end

  end
end


