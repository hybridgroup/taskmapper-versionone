module TaskMapper::Provider
  module Versionone
    # Ticket class for taskmapper-versionone
    #
    
    class Ticket < TaskMapper::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets
      include VersiononeAPI::HasAssets


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

      def id
        scope_id = self['Asset'].attributes[:id].first

        if scope_id.index("Story:") != nil
          scope_id.gsub!("Story:", "")
        end

        scope_id.to_i
      end

      def href
        self['Asset'].attributes[:href].first
      end

      def title
        find_text_attribute 'Name'
      end

      def description
        find_text_attribute 'Description'
      end

      def requestor
        find_text_attribute 'RequestedBy'
      end

      def assignee
        find_value_attribute 'Owners.Name'
      end

      def status
        find_text_attribute 'Status.Name'
      end

      def resolution
        status
      end

      def priority
        find_text_attribute 'Priority.Name'
      end

      def project_id
        id = find_relation_id('Scope')
        if !id.nil?
          strip_asset_type(id, 'Scope')
        end
      end

      # Unsupported by Version One

      def created_at
        ''
      end

      def updated_at
        ''
      end




    end
  end
end
