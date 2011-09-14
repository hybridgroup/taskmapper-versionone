module TicketMaster::Provider
  module Versionone
    class Project < TicketMaster::Provider::Base::Project
      API = VersiononeAPI::Scope # The class to access the api's projects
      # declare needed overloaded methods here
      
      # copy from this.copy(that) copies that into this
      
      def self.find_by_attributes(attributes = {})
        self.search(attributes)
      end

      def tickets(*options)
          if options.first.is_a? Hash
            #options[0].merge!(:params => {:id => id})
            super(*options)
          elsif options.empty?
            tickets = VersiononeAPI::Issue.find(:all, :params => {:id => id}).collect { |ticket| TicketMaster::Provider::Versionone::Ticket.new ticket }
          else
            super(*options)
          end
      end  

      def name
        self[:Attribute][2]
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

      def id
        scope_id = self[:id]
        scope_id.gsub!("Scope:", "")
      end

    end
  end
end


