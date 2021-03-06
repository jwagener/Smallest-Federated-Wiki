require File.dirname(__FILE__) + '/spec_helper'
require 'json'

# TODO: now that there is a Page spec and an integration spec, we should
# mock and stub the page writing in these tests.
shared_examples_for "Welcome as HTML" do
  let!(:versions) {
    log = `git log -10 --oneline`
    log.split("\n").map{ |e| e.split(' ').first }
  }
  it "renders the page" do
    last_response.status.should == 200
  end

  it "has a section with class 'main'" do
    @body.should match(/<section class='main'>/)
  end

  it "has a div with class 'page' and id 'welcome-visitors'" do
    @body.should match(/<div class='page' .*?id='welcome-visitors'>/)
  end

  it "has the latest commit in the head" do
    versions.each do |version|
      @body.should match(version)
    end
  end
end

describe "GET /" do
  before(:all) do
    get "/"
    @response = last_response
    @body = last_response.body
  end

  it_behaves_like 'Welcome as HTML'
end

describe "GET /welcome-visitors.html" do
  before(:all) do
    get "/welcome-visitors.html"
    @response = last_response
    @body = last_response.body
  end

  it_behaves_like 'Welcome as HTML'
end

describe "GET /view/welcome-visitors" do
  before(:all) do
    get "/view/welcome-visitors"
    @response = last_response
    @body = last_response.body
  end

  it_behaves_like 'Welcome as HTML'
end

describe "GET /view/welcome-visitors/view/indie-web-camp" do
  before(:all) do
    get "/view/welcome-visitors/view/indie-web-camp"
    @response = last_response
    @body = last_response.body
  end

  it_behaves_like 'Welcome as HTML'

  it "has a div with class 'page' and id 'indie-web-camp'" do
    @body.should match(/<div class='page' id='indie-web-camp'>/)
  end
end

describe "GET /welcome-visitors.json" do
  before(:all) do
    get "/welcome-visitors.json"
    @response = last_response
    @body = last_response.body
  end

  it "returns 200" do
    last_response.status.should == 200
  end

  it "returns Content-Type application/json" do
    last_response.header["Content-Type"].should == "application/json"
  end

  it "returns valid JSON" do
    expect {
      JSON.parse(@body)
    }.should_not raise_error
  end

  context "JSON from GET /welcome-visitors.json" do
    before(:all) do
      @json = JSON.parse(@body)
    end

    it "has a title string" do
      @json['title'].class.should == String
    end

    it "has a story arry" do
      @json['story'].class.should == Array
    end

    it "has paragraph as first item in story" do
      @json['story'].first['type'].should == 'paragraph'
    end

    it "has paragraph with text string" do
      @json['story'].first['text'].class.should == String
    end
  end
end

describe "GET /non-existent-test-page" do
  before(:all) do
    @non_existent_page = "#{TestDirs::TEST_DATA_DIR}/pages/non-existent-test-page"
    `rm -f #{@non_existent_page}`
  end

  it "should return 404" do
    get "/non-existent-test-page.json"
    last_response.status.should == 404
  end

end

describe "PUT /non-existent-test-page" do
  before(:all) do
    @non_existent_page = "#{TestDirs::TEST_DATA_DIR}/pages/non-existent-test-page"
    `rm -f #{@non_existent_page}`
  end

  it "should create page" do
    action = {'type' => 'create', 'id' =>  "123foobar", 'item' => {'title' => 'non-existent-test-page'}}
    put "/page/non-existent-test-page/action", :action => action.to_json
    last_response.status.should == 200
    File.exist?(@non_existent_page).should == true
  end
end

describe "PUT /welcome-visitors" do

  it "should respond with 409" do
    action = {'type' => 'create', 'id' =>  "123foobar", 'item' => {'title' => 'welcome-visitors'}}
    put "/page/welcome-visitors/action", :action => action.to_json
    last_response.status.should == 409
  end

end

describe "PUT /foo twice" do
  it "should return a 409 when recreating existing page" do
    page_file = "#{TestDirs::TEST_DATA_DIR}/pages/foo"
    File.exist?(page_file).should == false

    action = {'type' => 'create', 'id' =>  "123foobar", 'item' => {'title' => 'foo'}}
    put "/page/foo/action", :action => action.to_json

    last_response.status.should == 200
    File.exist?(page_file).should == true
    page_file_contents = File.read(page_file)

    action = {'type' => 'create', 'id' =>  "123foobar", 'item' => {'title' => 'spam'}}
    put "/page/foo/action", :action => action.to_json
    last_response.status.should == 409
    File.read(page_file).should == page_file_contents
  end
end
