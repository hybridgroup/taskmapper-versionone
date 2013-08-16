module TaskMapper::Provider
  module Versionone
    # Ticket class for taskmapper-versionone
    #
    
    class Ticket < TaskMapper::Provider::Base::Ticket
      API = VersiononeAPI::Issue # The class to access the api's tickets
      # declare needed overloaded methods here
      def initialize(*object)
        if object.first
          args = object
          object = args.shift
          @system_data = {:client => object}
          unless object.is_a? Hash
           hash = {:href => object.href,
                   :id => object.id}
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

      def id
        story_id = self[:id]

        if story_id.index("Story:") != nil
          story_id.gsub!("Story:", "")
        end

        story_id.to_i
      end

      
    end
  end
end
