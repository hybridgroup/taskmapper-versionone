require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapperVersionone" do 

  before(:each) do 
    @tm = TaskMapper.new(:versionone, {:server => 'http://server/Trial30', :username => 'admin', :password => 'admin'})
  end

  context "Initialization and validation" do 
    it "should be able to initialize a taskmapper object" do 
      @tm.should be_an_instance_of(TaskMapper)
      @tm.should be_kind_of(TaskMapper::Provider::Versionone)
    end
  end
end
