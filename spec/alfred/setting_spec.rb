require "spec_helper"

describe "Setting with yaml as backend" do
  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new
  end

  it "should use yaml as defualt backend" do
    @alfred.setting.format.should == "yaml"
  end

  it "should correctly load settings" do
    @alfred.setting[:id].should == "me.zhaowu.alfred-workflow-gem"
  end

  it "should correctly save settings" do
    @alfred.setting[:language] = "Chinese"
    @alfred.setting.dump(:flush => true)

    @alfred.setting.load
    @alfred.setting[:language].should == "Chinese"
  end


  after :all do
    reset_workflow
    File.unlink(@alfred.setting.backend_file)
  end

end




# describe "Setting with plist as backend" do
  # before :all do
    # setup_workflow
    # @alfred =  Alfred::Core.new

    # @alfred.setting do
      # @format = 'plist'
    # end
  # end

  # it "should correctly load settings" do
    # @alfred.setting['id'].should == "me.zhaowu.alfred-workflow-gem"
  # end

  # it "should correctly save settings" do
    # @alfred.setting['language'] = "English"
    # @alfred.setting.dump(:flush => true)

    # @alfred.setting['language'].should == "English"
  # end


  # after :all do
    # reset_workflow
    # File.unlink(@alfred.setting.backend_file)
  # end

# end





