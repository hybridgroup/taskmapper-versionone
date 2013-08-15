require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Versionone::Project" do

  before(:each) do

    ActiveResource::HttpMock.respond_to do |mock|
      headers = headers_for('admin', 'admin')
      mock.get '/Trial30/rest-1.v1/Data/Scope', headers, fixture_for('Scope'), 200
    end
    @tm = TaskMapper.new(:versionone, :server => 'http://server/Trial30', :username => 'admin', :password => 'admin')
  end

  context "Loading all projects" do
    it "should be able to retrieve all projects" do
      projects = @tm.projects
      projects.should be_an_instance_of(Array)
      projects.first.should be_an_instance_of(TaskMapper::Provider::Versionone::Project)
    end
  end
end
