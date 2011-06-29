require 'rubygems'
require 'active_support'
require 'active_resource'


# Ruby lib for working with the VersionOne API's XML interface.
# You should set the authentication using your login
# credentials with HTTP Basic Authentication.

# This library is a small wrapper around the REST interface

module VersiononeAPI
  class Error < StandardError; end
  class << self

    #Sets up basic authentication credentials for all the resources.
    def authenticate(servname, username, password)
      @server   = servname
      @username = username
      @password = password
      self::Base.user = username
      self::Base.password = password

      resources.each do |klass|
        klass.site = "#{servname}rest-1.v1/Data/"
      end
    end

    def resources
      @resources ||= []
    end
  end

  class Base < ActiveResource::Base
    def self.inherited(base)
      VersiononeAPI.resources << base
      super
    end
  end

   # Find projects
  #
  #   VersiononeAPI::Project.find(:all) # find all projects for the current account.
  #   VersiononeAPI::Project.find('my_project')   # find individual project by ID
  #
  # Creating a Project
  #
  #   project = VersiononeAPI::Project.new(:name => 'Ninja Whammy Jammy')
  #   project.save
  #   # => true
  #
  #
  # Updating a Project
  #
  #   project = VersiononeAPI::Project.find('my_project')
  #   project.name = "A new name"
  #   project.save
  #
  # Finding tickets
  # 
  #   project = VersiononeAPI::Project.find('my_project')
  #   project.tickets
  #

  class Scope < Base

      def self.collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Scope#{query_string(query_options)}"
      end

      def self.instantiate_collection(collection, prefix_options = {})
        objects = collection["Asset"]
        objects.collect! { |record| instantiate_record(record, prefix_options) }
      end

      def self.element_path(id, prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Scope/#{URI.escape id.to_s}#{query_string(query_options)}"
      end

      def encode(options={})
        val = ""
        val += "<Asset>"
        attributes.each_pair do |key, value|
          val += "<Attribute name='#{key}' act='set'>#{value}</Attribute>"
        end
        val += "</Asset>"
      end

  end

  class Task < Base

  end

end
