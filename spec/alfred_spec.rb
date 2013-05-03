require "spec_helper"

describe "Alfred" do

  before :all do
    setup_workflow
    @alfred =  Alfred::Core.new
  end

  it "should return a valid bundle id" do
    @alfred.bundle_id.should == "me.zhaowu.alfred-workflow-gem"
  end

  context "Help" do
    before :all do
      @alfred.with_help_feedback = true
    end

    it "should have correct default setting file" do
      @alfred.workflow_setting.setting_file.should eq 'settings.yaml'
      ap @alfred.help_feedback
    end


    it "should generate url feedback" do
      # puts @alfred.help_feedback.shoe
    end

  end

  after :all do
    reset_workflow
  end

end


