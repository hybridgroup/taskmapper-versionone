module TaskMapper::Provider
  module Versionone
    class Project < TaskMapper::Provider::Base::Project
      include VersiononeAPI::HasAssets
      API = VersiononeAPI::Scope # The class to access the api's projects
      # declare needed overloaded methods here

      attr_accessor :prefix_options
      alias_method :stories, :tickets
      alias_method :story, :ticket

      def initialize(*object)
        if object.first
          object = object.first
          @system_data = {:client => object}
          unless object.is_a? Hash
            hash = {:id => find_asset_id(object, 'Scope'),
                    :description => find_text_attribute(object, 'Description'),
                    :created_at => '',
                    :updated_at => '',
                    :name => find_text_attribute(object, 'Name'),
                    :owner => find_text_attribute(object, 'Owner.Name')}
          else
            hash = object
          end
          super hash
        end
      end

      # copy from this.copy(that) copies that into this
      
      def self.find_by_attributes(attributes = {})
        self.search(attributes)
      end

      def tickets(*options)
          if options.first.is_a? Hash
            #options[0].merge!(:params => {:id => id})
            super(*options)
          elsif options.empty?
            tickets = VersiononeAPI::Issue.find(:all, :params => {:where => "Scope='Scope:#{id}'" }).collect { |ticket| TaskMapper::Provider::Versionone::Ticket.new ticket }
          else
            super(*options)
          end
      end  

      def ticket!(*options)
        options[0].merge!(:id => id) if options.first.is_a?(Hash)
        provider_parent(self.class)::Ticket.create(*options)
      end

      def copy(project)
        project.tickets.each do |ticket|
          copy_ticket = self.ticket!(:title => ticket.title, :description => ticket.description)
          ticket.comments.each do |comment|
            copy_ticket.comment!(:body => comment.body)
            sleep 1
          end
        end
      end

    end
  end
end


