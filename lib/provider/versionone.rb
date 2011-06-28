module TicketMaster::Provider
  # This is the Versionone Provider for ticketmaster
  module Versionone
    include TicketMaster::Provider::Base
    TICKET_API = Versionone::Ticket # The class to access the api's tickets
    PROJECT_API = Versionone::Project # The class to access the api's projects
    
    # This is for cases when you want to instantiate using TicketMaster::Provider::Versionone.new(auth)
    def self.new(auth = {})
      TicketMaster.new(:versionone, auth)
    end
    
    # Providers must define an authorize method. This is used to initialize and set authentication
    # parameters to access the API
    def authorize(auth = {})
      @authentication ||= TicketMaster::Authenticator.new(auth)
      auth = @authentication
      if auth.servname? and auth.username.blank? and auth.password.blank?
        raise "Please provide server, username and password"
      end
      VersiononeAPI.authenticate(auth.servname, auth.username, auth.password)
    end
    
    # declare needed overloaded methods here

    def valid?

    end
    
  end
end


