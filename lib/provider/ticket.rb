module TicketMaster::Provider
  module Versionone
    # Ticket class for ticketmaster-versionone
    #
    
    class Ticket < TicketMaster::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets
      # declare needed overloaded methods here
      def initialize(*object)
        if object.first
          args = object
          object = args.shift
          @system_data = {:client => object}
          unless object.is_a? Hash
           hash = {:href => object.href,
                   :id => object.idref}
          else
            hash = object
          end
          super hash
        end
      end

      
      def self.create(*options)
        issue = API.new(*options)
        ticket = self.new issue
        issue.save
        ticket
      end
      
    end
  end
end
