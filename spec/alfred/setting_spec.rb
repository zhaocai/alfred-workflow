require "spec_helper"

describe "Setting with yaml as backend" do
  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new
  end

  it "should use yaml as defualt backend" do
    @setting = @alfred.setting
    @setting.format.should == "yaml"
  end

  it "should correctly load settings" do
    settings = @alfred.setting.load
    settings[:id].should == "me.zhaowu.alfred-workflow-gem"
  end

  it "should correctly save settings" do
    settings = @alfred.setting.load
    settings[:language] = "Chinese"
    @alfred.setting.dump(settings, :flush => true)

    settings = @alfred.setting.load
    settings[:language].should == "Chinese"
  end


  after :all do
    reset_workflow
    File.unlink(@alfred.setting.setting_file)
  end

end




describe "Setting with plist as backend" do
  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new

    @alfred.setting do
      use_setting_file :format => 'plist'
    end
  end

  it "should correctly load settings" do
    settings = @alfred.setting.load
    settings['id'].should == "me.zhaowu.alfred-workflow-gem"
  end

  it "should correctly save settings" do
    settings = @alfred.setting.load
    settings['language'] = "English"
    @alfred.setting.dump(settings, :flush => true)

    settings = @alfred.setting.load
    settings['language'].should == "English"
  end


  after :all do
    reset_workflow
    File.unlink(@alfred.setting.setting_file)
  end

end





