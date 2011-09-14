require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TicketMasterVersionone" do 

  context "Initialization and validation" do 
    it "should be able to initialize a ticketmaster object" do 
      @tm = TicketMaster.new(:versionone, {:servname => 'http://server/Trial30', :username => 'admin', :password => 'admin'})
      @tm.should be_an_instance_of(TicketMaster)
      @tm.should be_kind_of(TicketMaster::Provider::Versionone)
    end

    it "should validate the ticketmaster instance" do 
      @tm.valid?.should be_true
    end

  end
end
