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

      if auth.server.blank?
        raise "Please provide server url"
      elsif (auth.username.blank? && auth.password.blank?) && auth.access_token.blank?
        raise "Please provide username and password or V1 Access Token"
      end
      if !auth.access_token.blank?
        VersiononeAPI.authenticate_token(auth.server, auth.access_token)
      else
        VersiononeAPI.authenticate(auth.server, auth.username, auth.password)
      end
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
