module TaskMapper::Provider
  module Versionone
    # Ticket class for taskmapper-versionone
    #
    
    class Ticket < TaskMapper::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets

      attr_accessor :prefix_options


      def self.create(*options)
        issue = API.new(*options)
        ticket = self.new issue
        issue.save
        ticket
      end

      ## {:where => "Scope='Scope:#{id}'" }
      # Accepts an integer id and returns the single ticket instance
      # Must be defined by the provider
      def self.find_by_id(project_id, ticket_id)
        if self::API.is_a? Class
          self.new self::API.find(ticket_id, :params => {:where => "Scope='Scope:#{project_id}'" })
        else
          raise TaskMapper::Exception.new("#{self.name}::#{this_method} method must be implemented by the provider")
        end
      end

      # This is a helper method to find
      def self.search(project_id, options = {}, limit = 1000)
        if self::API.is_a? Class
          tickets = self::API.find(:all, :params => {:where => "Scope='Scope:#{project_id}'" }).collect { |ticket| self.new ticket }
          search_by_attribute(tickets, options, limit)
        else
          raise TaskMapper::Exception.new("#{self.name}::#{this_method} method must be implemented by the provider")
        end
      end

      def resolution
        self.status
      end

      def resolution=(value)
        self.status = value
      end

    end
  end
end
