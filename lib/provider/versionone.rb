module TaskMapper::Provider
  # This is the Versionone Provider for taskmapper
  module Versionone
    include TaskMapper::Provider::Base
    TICKET_API = Versionone::Ticket # The class to access the api's tickets
    PROJECT_API = Versionone::Project # The class to access the api's projects
    
    # This is for cases when you want to instantiate using TaskMapper::Provider::Versionone.new(auth)
    def self.new(auth = {})
      TaskMapper.new(:versionone, auth)
    end
    
    # Providers must define an authorize method. This is used to initialize and set authentication
    # parameters to access the API
    def authorize(auth = {})
      @authentication ||= TaskMapper::Authenticator.new(auth)
      auth = @authentication
      if auth.server.blank? and auth.username.blank? and auth.password.blank?
        raise "Please provide server, username and password"
      end
      VersiononeAPI.authenticate(auth.server, auth.username, auth.password)
    end
    
    # declare needed overloaded methods here

    def valid?
      begin
        !PROJECT_API.find(:all).nil?
      rescue
        false
      end
    end
    
  end
end


