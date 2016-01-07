module TaskMapper::Provider
  module Versionone
    # Ticket class for taskmapper-versionone
    #

    class Ticket < TaskMapper::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets

      attr_accessor :prefix_options


      def self.create(*options)
        issue = API.new(*options)
        issue.save!
        ticket = self.find_by_id(issue.project_id, issue.id, issue.issuetype)
        ticket
      end

      ## {:where => "Scope='Scope:#{id}'" }
      # Accepts an integer id and returns the single ticket instance
      # Must be defined by the provider
      def self.find_by_id(project_id, ticket_id, issuetype = 'story')
        if self::API.is_a? Class
          tix = nil
          if issuetype.downcase == 'epic'
            tix = self::API.find_epics(project_id)
            tix = tix.last
          else
            tix = self::API.find(ticket_id, self::API.query_params_for_scope(project_id))
          end
          self.new tix
        else
          raise TaskMapper::Exception.new("#{self.name}::#{this_method} method must be implemented by the provider")
        end
      end

      # This is a helper method to find
      def self.search(project_id, options = {}, limit = 1000)
        if self::API.is_a? Class
          tickets = self::API.find(:all, self::API.query_params_for_scope(project_id)).collect { |ticket| self.new ticket }
          search_by_attribute(tickets, options, limit)
        else
          raise TaskMapper::Exception.new("#{self.name}::#{this_method} method must be implemented by the provider")
        end
      end

      def save
        if @system_data and (something = @system_data[:client]) and something.respond_to?(:attributes)
          changes = 0
          updated_fields = []
          something.attributes.each do |k, v|
            if self.send(k) != v
              something.send(k + '=', self.send(k))
              updated_fields << k
              changes += 1
              p something

            elsif self.send(k) != nil?
              p something
            end
          end
          something.class.set_updated_fields updated_fields
          something.save if changes > 0
        else
          raise TaskMapper::Exception.new("#{self.class.name}::#{this_method} method must be implemented by the provider")
        end
      end

      def resolution
        self.status
      end

      def resolution=(value)
        self.status = value
      end

      def url
        return href if href

        "#{VersiononeAPI.server}story.mvc/Summary?oidToken=Story%3A#{id}"
      end

      # def status
      #   return :completed if self.asset_state == :closed
      #   return :unstarted if self.asset_state == :deleted
      #   return :started if (!self.status_name.nil? && !self.status_name.empty?)
      #
      #   :unstarted
      # end

      def destroy
        @system_data[:client].destroy
      end
    end
  end
end
