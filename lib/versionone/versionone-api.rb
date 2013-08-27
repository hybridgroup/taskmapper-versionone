require 'rubygems'
require 'nokogiri'
require File.expand_path(File.dirname(__FILE__) + '/nokogiri_to_hash')
require 'active_support'
require 'active_resource'


# Ruby lib for working with the VersionOne API's XML interface.
# You should set the authentication using your login
# credentials with HTTP Basic Authentication.

# This library is a small wrapper around the REST interface

module VersiononeAPI

  module NokogiriXmlFormat
    extend self

    def extension
      "xml"
    end

    def mime_type
      "application/xml"
    end

    def encode(hash, options={})
      hash.to_xml(options)
    end

    def decode(xml)
      Nokogiri::XML.parse(xml).to_hash('*')
    end
  end

  module HasAssets

    def find_child_with_name(asset_container, child_type, name)
      asset(asset_container)[:children].find_all { |child|
        !child[child_type].nil?
      }.collect { |child|
        child[child_type]
      }.find {|attr|
        attr[:name].first == name
      }[:children]
    end

    def find_attribute(asset_container, attribute_name)
      find_child_with_name(asset_container, :Attribute, attribute_name)
    end

    def find_text_attribute(asset_container, attribute_name)
      children = find_attribute(asset_container, attribute_name)
      !children.empty? ? children.first[:content] : ''
    end

    def find_value_attribute(asset_container, attribute_name)
      children = find_attribute(asset_container, attribute_name)
      !children.empty? ? children.first[:Value][:children].first[:content] : ''
    end

    def find_relation_id(asset_container, name)
      relation = find_child_with_name(asset_container, :Relation, name)
      if(!relation.empty?)
        relation.first[:Asset][:idref].first
      end

    end

    def find_asset_href(asset_container)
      asset(asset_container)[:href]
    end

    def find_asset_id(asset_container, asset_type)
      strip_asset_type(asset(asset_container)[:id].first, asset_type).to_i
    end

    def strip_asset_type(id, asset_type)
      id.gsub!("#{asset_type}:", '')
    end

    def asset(asset_container)
      asset_container[:Asset]
    end

  end

  class Error < StandardError; end
  class << self

    #Sets up basic authentication credentials for all the resources.
    def authenticate(servname, username, password)
      @server = servname
      @server << '/' unless @server.end_with?('/')
      @username = username
      @password = password
      self::Base.user = username
      self::Base.password = password

      resources.each do |klass|
        klass.site = klass.site_format % "#{@server}rest-1.v1/Data/"
      end
    end

    def resources
      @resources ||= []
    end
  end

  class Base < ActiveResource::Base
    self.format = NokogiriXmlFormat


    def self.inherited(base)
      VersiononeAPI.resources << base
      class << base
        attr_accessor :site_format
      end
      base.site_format = '%s'
      super
    end

    def encode(options={})
      val = ''
      val += '<Asset>'
      attributes.each_pair do |key, value|
        if(key == 'project_id')
          val += "<Relation name='Scope' act='set'><Asset idref='Scope:#{value}' /></Relation>"
        elsif !getUpdateableFieldName(key).nil?
          val += "<Attribute name='#{getUpdateableFieldName(key)}' act='set'>#{value}</Attribute>"
        end

      end
      val += '</Asset>'
    end

    def getUpdateableFieldName(key)
      nil
    end

    def self.instantiate_collection(collection, prefix_options = {})
      objects = collection.find {|x| x.has_key? :Assets }[:Assets]
      objects[:children].collect! { |record| instantiate_record(record, prefix_options) }
    end

    def update
      connection.post(element_path(prefix_options), encode, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def load_attributes_from_response(response)
      if (response_code_allows_body?(response.code) &&
          (response['Content-Length'].nil? || response['Content-Length'] != "0") &&
          !response.body.nil? && response.body.strip.size > 0)
        decoded = self.class.format.decode(response.body)
        decoded = decoded.first if decoded.is_a? Array

        load(decoded, true)
        @persisted = true
      end
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
      extend HasAssets

      def self.collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Scope#{query_string(query_options)}"
      end

      def self.element_path(id, prefix_options = {}, query_options = nil)
        #id format is "resource_name:id", but element_path just needs the id, without the resource_name.
        scope_id = id.to_s
        scope_id.gsub!("Scope:", "")
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Scope/#{URI.escape scope_id}#{query_string(query_options)}"
      end


      def self.instantiate_record(record, prefix_option = {})
        object = record
        object = object.first if object.kind_of? Array

        simplified = {:id => find_asset_id(object, 'Scope'),
         :description => find_text_attribute(object, 'Description'),
         :created_at => '',
         :updated_at => '',
         :name => find_text_attribute(object, 'Name'),
         :owner => find_text_attribute(object, 'Owner.Name')}

        super(simplified, prefix_option)
      end

      UPDATEABLE_FIELDS = {
          'name' => 'Name',
          'description' => 'Description',
          #'owner' => 'Owner.Name'
      }

      def getUpdateableFieldName(key)
        UPDATEABLE_FIELDS[key] || key
      end

      def tickets(options = {})
        Issue.find(:all, :params => options.update(:scope_id => scope_id))
      end

      def scope_id
        scope_id = attributes[:id]
        scope_id.gsub!('Scope:', '')
      end

  end

  class Issue < Base
    extend HasAssets

      def self.collection_path(prefix_options = {}, query_options = nil)
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Story#{query_string(query_options)}"
      end

      def self.element_path(id, prefix_options = {}, query_options = nil)
        scope_id = id.to_s
        scope_id.gsub!("Story:", "")
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{prefix(prefix_options)}Story/#{URI.escape scope_id}#{query_string(query_options)}"
      end


    def self.instantiate_record(record, prefix_option = {})
      object = record
      object = object.first if object.kind_of? Array

      simplified = {:id => find_asset_id(object, 'Story'),
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

      super(simplified, prefix_option)
    end

    # Takes a response from a typical create post and pulls the ID out
    def id_from_response(response)
      decoded = self.class.format.decode(response.body).first
      self.class.find_asset_id(decoded, 'Story')

    end

    UPDATEABLE_FIELDS = {
        'title' => 'Name',
        'description' => 'Description',
        #'requestor' => 'RequestedBy',
        #'priority' => 'Priority.Name',
        #'status' => 'Status.Name',
        #'assignee' => 'Owners.Name'
    }

    def getUpdateableFieldName(key)
      UPDATEABLE_FIELDS[key]
    end

  end

end
