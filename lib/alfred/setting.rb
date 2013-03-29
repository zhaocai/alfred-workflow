require 'yaml'

module Alfred

  class Setting
    attr_accessor :settings

    def initialize(alfred, setting_file = nil)
      @core = alfred
      @setting_file = setting_file if setting_file


    end

    # settings
    def setting_file
      @setting_file ||= File.join(@core.storage_path, 'setting.yml')
    end

    def load
      unless File.exist?(setting_file)
        @settings = {:id => @core.bundle_id}
        dump
      end

      @settings = YAML::load( File.read(setting_file) )
    end

    def dump(settings = nil, opts = {})
      settings = @settings unless settings

      File.open(setting_file, "wb") { |f|
        YAML::dump(settings, f)
        f.flush if opts[:flush]
      }
    end

  end
end


