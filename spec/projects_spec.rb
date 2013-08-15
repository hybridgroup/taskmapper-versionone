require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Versionone::Project" do

  before(:all) do
    headers = headers_for('admin', 'admin')
    @project_id = 1009
    ActiveResource::HttpMock.respond_to do |mock|
      mock.get '/Trial30/rest-1.v1/Data/Scope', headers, fixture_for('Scope'), 200
      mock.get '/Trial30/rest-1.v1/Data/Scope/1009', headers, fixture_for('Scope'), 200
    end
  end

  before(:each) do
    @taskmapper = TaskMapper.new(:versionone, :server => 'http://server/Trial30', :username => 'admin', :password => 'admin')
    @klass = TaskMapper::Provider::Versionone::Project
  end

  context "Loading all projects" do
    it "should be able to retrieve all projects" do
      projects = @taskmapper.projects
      projects.should be_an_instance_of(Array)
      projects.first.should be_an_instance_of(@klass)
      projects.first.id.should == @project_id
    end

    it "should be able to retrieve projects from an array of ids" do
      projects = @taskmapper.projects([@project_id])
      projects.should be_an_instance_of(Array)
      projects.first.should be_an_instance_of(@klass)
      projects.first.id.should == @project_id
      projects.length.should == 1
    end

    it "should be able to load all projects from attributes" do
      projects = @taskmapper.projects(:id => @project_id)
      projects.should be_an_instance_of(Array)
      projects.first.should be_an_instance_of(@klass)
      projects.first.id.should == @project_id
    end

    it "should be able to find a project" do
      @taskmapper.project.should == @klass
      @taskmapper.project.find(@project_id).should be_an_instance_of(@klass)
    end

    it "should be able to find a project by id" do
      @taskmapper.project(@project_id).should be_an_instance_of(@klass)
      @taskmapper.project(@project_id).id.should == @project_id
    end

    it "should be able to find a project by attributes" do
      @taskmapper.project(:id => @project_id).id.should == @project_id
      @taskmapper.project(:id => @project_id).should be_an_instance_of(@klass)
    end

    it "should be able to update and save a project" do
      pending("using posts in the api access")
      @project = @taskmapper.project(@project_id)
      @project.update!(:name => 'some new name').should == true
      @project.name = 'this is a change'
      @project.save.should == true
    end

  end
end
