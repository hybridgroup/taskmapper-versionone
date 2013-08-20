module TaskMapper::Provider
  module Versionone
    # Ticket class for taskmapper-versionone
    #
    
    class Ticket < TaskMapper::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets
      include VersiononeAPI::HasAssets


      attr_accessor :prefix_options

      def initialize(*object)
        if object.first
          object = object.first
          @system_data = {:client => object}
          hash = {:id => find_asset_id(object, 'Story'),
                  :href => find_asset_href(object),
                  :title => find_text_attribute(object, 'Name'),
                  :description => find_text_attribute(object, 'Description'),
                  :requestor => find_text_attribute(object, 'RequestedBy'),
                  :project_id => strip_asset_type(find_relation_id(object, 'Scope'), 'Scope'),
                  :priority => find_text_attribute(object, 'Priority.Name'),
                  :status => find_text_attribute(object, 'Status.Name'),
                  :assignee => find_value_attribute(object, 'Owners.Name') ,
                  # Unsupported by Version One
                  :created_at => '',
                  :updated_at => ''}
          super hash
        end
      end

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
        status
      end

    end
  end
end
