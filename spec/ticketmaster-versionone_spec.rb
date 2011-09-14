require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TicketMasterVersionone" do 

  before(:each) do 
    @tm = TicketMaster.new(:versionone, {:server => 'http://server/Trial30', :username => 'admin', :password => 'admin'})
  end

  context "Initialization and validation" do 
    it "should be able to initialize a ticketmaster object" do 
      @tm.should be_an_instance_of(TicketMaster)
      @tm.should be_kind_of(TicketMaster::Provider::Versionone)
    end
  end
end
