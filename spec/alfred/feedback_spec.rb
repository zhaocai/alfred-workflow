require "spec_helper"

describe "Feedback" do

  before :all do
    setup_workflow

    @alfred =  Alfred::Core.new
    @feedback = Alfred::Feedback.new(@alfred)

    @item_elements = %w{title subtitle icon}
    @item_attributes = %w{uid arg autocomplete}
  end

  context "Feedback" do

    it "should create a basic XML response" do
      @feedback.add_item(:uid          => "uid"          ,
                         :arg          => "arg"          ,
                         :autocomplete => "autocomplete" ,
                         :title        => "Title"        ,
                         :subtitle     => "Subtitle")

      xml_data = <<-END.strip_heredoc
      <?xml version="1.0"?>
      <items>
        <item valid="yes" autocomplete="autocomplete" uid="uid">
          <title>Title</title>
          <arg>Arg</arg>
          <subtitle>Subtitle</subtitle>
          <icon>icon.png</icon>
        </item>
      </items>
      END

      compare_xml(xml_data, @feedback.to_xml).should == true
    end

    it "should not have uid if not presented" do

      @feedback.items = []
      @feedback.add_item(:arg          => "arg"          ,
                         :autocomplete => "autocomplete" ,
                         :title        => "Title"        ,
                         :subtitle     => "Subtitle")

      xml_data = <<-END.strip_heredoc
      <?xml version="1.0"?>
      <items>
        <item valid="yes" autocomplete="autocomplete">
          <title>Title</title>
          <arg>Arg</arg>
          <subtitle>Subtitle</subtitle>
          <icon>icon.png</icon>
        </item>
      </items>
      END

      compare_xml(xml_data, @feedback.to_xml).should == true
    end

  end

  context "Cached Feedback" do
    it "should have correct default cache file" do
      @alfred.with_cached_feedback do
        use_cache_file :expire => 10
      end
      fb = @alfred.feedback
      fb.backend_file.should == File.join(@alfred.volatile_storage_path, "cached_feedback")
    end

    it "should set correct cache file" do
      alfred =  Alfred::Core.new
      alfred.with_cached_feedback do
        use_cache_file :file => "new_cached_feedback"
      end
      fb = alfred.feedback
      fb.backend_file.should == "new_cached_feedback"
    end

    context "With Valid Cached File" do
      before :all do
        @alfred.with_cached_feedback do
          use_cache_file
        end

        fb = @alfred.feedback

        fb.add_item(:uid          => "uid"          ,
                    :arg          => "arg"          ,
                    :autocomplete => "autocomplete" ,
                    :title        => "Title"        ,
                    :subtitle     => "Subtitle")

        @xml_data = <<-END.strip_heredoc
        <?xml version="1.0"?>
        <items>
          <item valid="yes" autocomplete="autocomplete" uid="uid">
            <title>Title</title>
            <arg>Arg</arg>
            <subtitle>Subtitle</subtitle>
            <icon>icon.png</icon>
          </item>
        </items>
        END
        fb.put_cached_feedback
      end


      it "should correctly load cached feedback" do
        alfred =  Alfred::Core.new
        alfred.with_cached_feedback do
          use_cache_file
        end

        fb = alfred.feedback

        compare_xml(@xml_data, fb.get_cached_feedback.to_xml).should == true
      end

      it "should expire as defined" do
        alfred =  Alfred::Core.new
        alfred.with_cached_feedback do
          use_cache_file :expire => 1
        end
        sleep 1
        fb = alfred.feedback
        fb.get_cached_feedback.should == nil

      end

    end
  end

  after :all do
    @alfred.with_cached_feedback
    fb = @alfred.feedback
    File.unlink(fb.backend_file)
    reset_workflow
  end

end
