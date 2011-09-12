module TicketMaster::Provider
  module Versionone
    class Project < TicketMaster::Provider::Base::Project
      API = VersiononeAPI::Scope # The class to access the api's projects
      # declare needed overloaded methods here
      
      # copy from this.copy(that) copies that into this
     #def initialize(*object)
     #  if object.first
     #    object = object.first
     #    @system_data = {:client => object}
     #    unless object.is_a? Hash
     #     hash = {:name => object.attributes[:Attribute][3],
     #             :description => object.attributes[:Attribute][0],
     #             :begindate => object.attributes[:Attribute][13],
     #             :enddate => object.attributes[:Attribute][7],
     #             :id => object.attributes[:id],
     #             :parent => object.attributes[:Attribute][18]}
     #    else
     #      hash = object
     #    end
     #    super hash
     #  end
     #end

      def tickets(*options)
          if options.first.is_a? Hash
            #options[0].merge!(:params => {:id => id})
            super(*options)
          elsif options.empty?
            puts id
            tickets = VersiononeAPI::Issue.find(:all, :params => {:id => id}).collect { |ticket| TicketMaster::Provider::Versionone::Ticket.new ticket }
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

      def id
        scope_id = self[:id]
        scope_id.gsub!("Scope:", "")
      end

    end
  end
end


