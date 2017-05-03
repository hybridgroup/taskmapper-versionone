module TaskMapper::Provider
  module Versionone
    class Project < TaskMapper::Provider::Base::Project
      API = VersiononeAPI::Scope # The class to access the api's projects
      # declare needed overloaded methods here

      attr_accessor :prefix_options
      alias_method :stories, :tickets
      alias_method :story, :ticket

      # copy from this.copy(that) copies that into this
      
      def self.find_by_attributes(attributes = {})
        self.search(attributes)
      end

      def tickets(*options)
        if options.first.is_a? Hash
          #options[0].merge!(:params => {:id => id})
          super(*options)
        elsif options.empty?
          tix = Project.issues_in_scope(id)
          unless self.child_project_ids.nil?
            child_project_ids.each { |id|
              child_issues = Project.issues_in_scope(id)
              tix = tix.concat(child_issues) unless child_issues.nil?
            }
          end
          tix
        else
          super(*options)
        end


      end

      def ticket!(*options)
        options[0].merge!(:project_id => id) if options.first.is_a?(Hash)
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

      private

      def self.issues_in_scope(id)
        tix =  VersiononeAPI::Issue.find_epics(id).collect { |ticket| TaskMapper::Provider::Versionone::Ticket.new ticket }
        tix += VersiononeAPI::Issue.find_stories(id).collect { |ticket| TaskMapper::Provider::Versionone::Ticket.new ticket }
        tix
      end

    end
  end
end


