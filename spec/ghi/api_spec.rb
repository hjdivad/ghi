$: << File.expand_path(File.dirname(__FILE__) + "/../lib")
require "ghi"
require "ghi/api"
require "ghi/issue"
include GHI

ISSUES_YAML = <<-YAML
---
issues:
- number: 1
  votes: 0
  created_at: 2009-04-17 14:55:33 -07:00
  body: my sweet, sweet issue
  title: new issue
  updated_at: 2009-04-17 14:55:33 -07:00
  user: schacon
  state: open
- number: 2
  votes: 0
  created_at: 2009-04-17 15:16:47 -07:00
  body: the body of a second issue
  title: another issue
  updated_at: 2009-04-17 15:16:47 -07:00
  user: schacon
  state: open
YAML

ISSUE_YAML = <<-YAML
---
issue:
  number: 1
  votes: 0
  created_at: 2009-04-17 14:55:33 -07:00
  body: my sweet, sweet issue
  title: new issue
  updated_at: 2009-04-17 14:55:33 -07:00
  user: schacon
  state: open
YAML

LABELS_YAML = <<-YAML
---
labels:
- testing
- test_label
YAML

COMMENT_YAML = <<-YAML
---
comment:
  comment: this is amazing
  status: saved
YAML

describe GHI::API do
  it "should require user and repo" do
    proc { API.new(nil, nil) }.should raise_error(API::InvalidConnection)
    proc { API.new("u", nil) }.should raise_error(API::InvalidConnection)
    proc { API.new(nil, "r") }.should raise_error(API::InvalidConnection)
    proc { API.new("u", "r") }.should_not raise_error(API::InvalidConnection)
  end

  describe "requests" do
    before :each do
      @api = API.new "stephencelis", "ghi"
      GHI.stub!(:login).and_return "stephencelis"
      GHI.stub!(:token).and_return "token"

      @h = mock(Net::HTTP)
      @h.stub(:start){|l| l.call}
    end

    it "should substitute url tokens" do
      @api.send(:url_path, :open).should ==
        "/api/v2/yaml/issues/open/stephencelis/ghi"
      @api.send(:url_path, :show, 1).should ==
        "/api/v2/yaml/issues/show/stephencelis/ghi/1"
      @api.send(:url_path, :search, :open, "me").should ==
        "/api/v2/yaml/issues/search/stephencelis/ghi/open/me"
      @api.send(:url_path, "label/add", "me").should ==
        "/api/v2/yaml/issues/label/add/stephencelis/ghi/me"
    end

    it "should process gets" do
      url_path  = "/api/v2/yaml/issues/open/stephencelis/ghi"
      query     = "?login=stephencelis&token=token"
      @api.stub!(:url_path).and_return url_path
      r = mock(Net::HTTPRequest)
      rs = mock(Net::HTTPResponse)
      Net::HTTP.should_receive(:new).once.and_return @h
      Net::HTTP::Get.should_receive(:new).once.with(url_path+query).and_return r
      @h.should_receive(:request).once.with(r).and_return rs
      rs.should_receive(:body).once.and_return ISSUES_YAML
      @api.list
    end

    it "should process posts" do
      url_path  = "/api/v2/yaml/issues/open/stephencelis/ghi"
      query     = { "login" => "stephencelis",
                    "token" => "token",
                    "title" => "Title",
                    "body"  => "Body" }
      @api.stub!(:url_path).and_return url_path
      r = mock(Net::HTTPRequest)
      rs = mock(Net::HTTPResponse)
      Net::HTTP.should_receive(:new).once.and_return @h
      Net::HTTP::Post.should_receive(:new).once.with(url_path).and_return r
      r.should_receive(:body=).once
      @h.should_receive(:request).once.with(r).and_return rs
      rs.should_receive(:body).once.and_return ISSUE_YAML
      @api.open "Title", "Body"
    end

    def expect_get_response( s )
      r = mock(Net::HTTPRequest)
      rs = mock(Net::HTTPResponse)
      Net::HTTP.should_receive(:new).once.and_return @h
      Net::HTTP::Get.should_receive(:new).once.and_return r
      @h.should_receive(:request).once.with(r).and_return rs
      rs.should_receive(:body).once.and_return s
    end

    def expect_post_response( s )
      r = mock(Net::HTTPRequest)
      rs = mock(Net::HTTPResponse)
      Net::HTTP.should_receive(:new).once.and_return @h
      Net::HTTP::Post.should_receive(:new).once.and_return r
      r.should_receive(:body=).once
      @h.should_receive(:request).once.with(r).and_return rs
      rs.should_receive(:body).once.and_return s
    end

    it "should search open by default" do
      @api.should_receive(:url_path).with(:search, :open, "me").and_return "u"
      expect_get_response ISSUES_YAML
      issues = @api.search "me"
      issues.should be_an_instance_of(Array)
      issues.each { |issue| issue.should be_an_instance_of(Issue) }
    end

    it "should search closed" do
      @api.should_receive(:url_path).with(:search, :closed, "me").and_return "u"
      expect_get_response ISSUES_YAML
      @api.search "me", :closed
    end

    it "should list open by default" do
      @api.should_receive(:url_path).with(:list, :open).and_return "u"
      expect_get_response ISSUES_YAML
      issues = @api.list
      issues.should be_an_instance_of(Array)
      issues.each { |issue| issue.should be_an_instance_of(Issue) }
    end

    it "should list closed" do
      @api.should_receive(:url_path).with(:list, :closed).and_return "u"
      expect_get_response ISSUES_YAML
      @api.list :closed
    end

    it "should show" do
      @api.should_receive(:url_path).with(:show, 1).and_return "u"
      expect_get_response ISSUE_YAML
      @api.show(1).should be_an_instance_of(Issue)
    end

    it "should open" do
      @api.should_receive(:url_path).with(:open).and_return "u"
      expect_post_response ISSUE_YAML
      @api.open("Title", "Body").should be_an_instance_of(Issue)
    end

    it "should edit" do
      @api.should_receive(:url_path).with(:edit, 1).and_return "u"
      expect_post_response ISSUE_YAML
      @api.edit(1, "Title", "Body").should be_an_instance_of(Issue)
    end

    it "should close" do
      @api.should_receive(:url_path).with(:close, 1).and_return "u"
      expect_post_response ISSUE_YAML
      @api.close(1).should be_an_instance_of(Issue)
    end

    it "should reopen" do
      @api.should_receive(:url_path).with(:reopen, 1).and_return "u"
      expect_post_response ISSUE_YAML
      @api.reopen(1).should be_an_instance_of(Issue)
    end

    it "should add labels" do
      @api.should_receive(:url_path).with("label/add", 1, "l").and_return "u"
      expect_post_response LABELS_YAML
      @api.add_label(1, "l").should be_an_instance_of(Array)
    end

    it "should remove labels" do
      @api.should_receive(:url_path).with("label/remove", 1, "l").and_return "u"
      expect_post_response LABELS_YAML
      @api.remove_label(1, "l").should be_an_instance_of(Array)
    end

    it "should comment, and escape values" do
      @api.should_receive(:url_path).with(:comment, 1).and_return "u"

      r = mock(Net::HTTPRequest)
      rs = mock(Net::HTTPResponse)
      Net::HTTP.should_receive(:new).once.and_return @h
      Net::HTTP::Post.should_receive(:new).once.and_return r
      r.should_receive(:body=).once do |body|
        body.should =~ /comment=Comment%26so/
      end
      @h.should_receive(:request).once.with(r).and_return rs
      rs.should_receive(:body).once.and_return COMMENT_YAML

      @api.comment(1, "Comment&so").should be_an_instance_of(Hash)
    end
  end
end
