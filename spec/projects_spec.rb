require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Versionone::Project" do 

  context "Loading all projects" do 
    it "should be able to retrieve all projects" do 
      @tm = TaskMapper.new(:versionone, :server => 'http://server/Trial30', :username => 'admin', :password => 'admin')
      projects = @tm.projects
      projects.should be_an_instance_of(Array)
      projects.first.should be_an_instance_of(TaskMapper::Provider::Versionone::Project)
    end
  end
end
