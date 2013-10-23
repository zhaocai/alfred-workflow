require "spec_helper"

describe "Setting with yaml as backend" do
  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new
  end

  it "should use yaml as defualt backend" do
    @alfred.workflow_setting.format.should == "yaml"
  end

  it "should correctly load settings" do
    @alfred.workflow_setting[:id].should == "me.zhaowu.alfred-workflow-gem"
  end

  it "should correctly save settings" do
    rand = rand(10**24-10)

    @alfred.workflow_setting[:rand] = rand
    @alfred.workflow_setting.dump(:flush => true)

    @alfred.workflow_setting.load
    @alfred.workflow_setting[:rand].should == rand

  end

  it "should handle common hash methods" do
    @alfred.workflow_setting.delete :rand

    @alfred.workflow_setting[:rand].should == nil
  end

  after :all do
    reset_workflow
  end

end





