require "spec_helper"

describe "Alfred" do

  before :all do
    @alfred =  Alfred::Core.new
    Dir.chdir("test/workflow/")
  end

  it "should return a valid bundle id" do
    @alfred.bundle_id.should == "me.zhaowu.alfred2-ruby-template"
  end

  context "Setting" do

    before :all do
      @setting = @alfred.setting
    end
    it "should correctly load settings" do
      settings = @setting.load
      settings[:id].should == "me.zhaowu.alfred2-ruby-template"
    end

    it "should correctly save settings" do
      settings = @setting.load
      settings[:language] = "Chinese"
      @setting.dump(settings, :flush => true)

      settings = @alfred.setting.load
      settings[:language].should == "Chinese"
    end

    after :all do
      File.unlink(@setting.setting_file)
    end

  end
end



