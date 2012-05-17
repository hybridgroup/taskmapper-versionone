module TaskMapper::Provider
  module Versioonne
    # The comment class for taskmapper-versioonne
    #
    # Do any mapping between TaskMapper and your system's comment model here
    # versions of the ticket.
    #
    class Comment < TaskMapper::Provider::Base::Comment
      #API = Versioonne::Comment # The class to access the api's comments
      # declare needed overloaded methods here
      
    end
  end
end
