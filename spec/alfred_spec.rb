require "spec_helper"

describe "Alfred" do

  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new
  end

  it "should return a valid bundle id" do
    @alfred.bundle_id.should == "me.zhaowu.alfred-workflow-gem"
  end

  it "should have correct default setting file" do
    @alfred.workflow_setting.backend_file.should eq File.join(Alfred.workflow_folder, "setting.yaml")
  end

  after :all do
    reset_workflow
  end

end


