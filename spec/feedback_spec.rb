require "spec_helper"

describe "Feedback" do

  before :all do
    @feedback = Alfred::Feedback.new
  end
  it "should create a basic XML response" do
    @feedback.add_item(:uid          => "uid"          ,
                       :arg          => "arg"          ,
                       :autocomplete => "autocomplete" ,
                       :title        => "Title"        ,
                       :subtitle     => "Subtitle")

    @feedback.to_xml.should == "<items><item arg='arg' autocomplete='autocomplete' uid='uid' valid='yes'><title>Title</title><subtitle>Subtitle</subtitle><icon>icon.png</icon></item></items>"
  end

end
