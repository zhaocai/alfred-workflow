require 'yaml'

module Alfred

  class Setting < ::Hash
    attr_accessor :backend_file
    attr_reader :format

    def initialize(alfred, &block)
      super()
      @core = alfred

      instance_eval(&block) if block_given?

      @format ||= "yaml"
      @backend_file ||= File.join(@core.storage_path, "setting.#{@format}")

      raise InvalidFormat, "#{format} is not suported." unless validate_format

      unless File.exist?(@backend_file)
        self.merge!({:id => @core.bundle_id})
        dump(:flush => true)
      else
        load
      end
    end

    def validate_format
      ['yaml'].include?(format)
    end

    def load
      send("load_from_#{format}".to_sym)
    end

    def dump(opts = {})
      send("dump_to_#{format}".to_sym, opts)
    end

    alias_method :close, :dump

    protected

    def load_from_yaml
      self.merge!(YAML::load_file(@backend_file))
    end

    def dump_to_yaml(opts = {})
      File.open(@backend_file, File::WRONLY|File::TRUNC|File::CREAT) { |f|
        YAML::dump(self, f)
        f.flush if opts[:flush]
      }
    end

  end
end


