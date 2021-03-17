require 'rubygems'
require 'nokogiri'
require File.expand_path(File.dirname(__FILE__) + '/nokogiri_to_hash')
require 'active_support'
require 'active_resource'
require 'active_support/core_ext/object/to_query'



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
      element = asset(asset_container)[:children].find_all { |child|
        child && !child[child_type].nil?
      }.collect { |child|
        child && child[child_type]
      }.find { |attr|
        attr[:name].first == name
      }
      element ? element[:children] : []
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

    def find_relation_ids(asset_container, attribute_name, id_type)
      relation = find_child_with_name(asset_container, :Relation, attribute_name)
      if relation and not relation.empty?
        relation.collect {|child|
          strip_asset_type(child[:Asset][:idref].first, id_type)}
      end
    end

    def find_relation_id(asset_container, name, id_type)
     ids = find_relation_ids(asset_container, name, id_type)
     ids.first unless ids.nil? or ids.empty?

    end

    def find_asset_href(asset_container)
      asset(asset_container)[:href]
    end

    def find_asset_id(asset_container, asset_type)
      strip_asset_type(asset(asset_container)[:id].first, asset_type).to_i
    end

    def find_full_asset_id(asset_container)
      asset(asset_container)[:id]
    end

    def strip_asset_type(id, asset_type)
      id.gsub!("#{asset_type}:", '') unless id.nil?
    end

    def asset(asset_container)
      asset_container[:Asset]
    end

  end

  class ActiveResource::Base
    # store the attribute value in a thread local variable
    class << self
      %w(host user password access_token).each do |attr|
        define_method(attr) do
          Thread.current["active_resource.#{attr}"]
        end

        define_method("#{attr}=") do |val|
          Thread.current["active_resource.#{attr}"] = val
        end
      end
    end
  end

  class Error < StandardError; end
  class << self

    %w(server).each do |attr|

      define_method(attr) do
        Thread.current["active_resource.#{attr}"]
      end

      define_method("#{attr}=") do |val|
        Thread.current["active_resource.#{attr}"] = val
      end
    end

    #Sets up basic authentication credentials for all the resources.
    def authenticate(servname, username, password)
      self.server = servname
      self.server << '/' unless self.server.end_with?('/')

      self::Base.user = username
      self::Base.password = password

      resources.each do |klass|
        klass.site = klass.site_format % "#{self.server}rest-1.v1/Data/"
      end
    end

    #Sets up basic authentication credentials for all the resources.
    def authenticate_token(servname, access_token)
      self.server = servname
      self.server << '/' unless self.server.end_with?('/')

      self::Base.headers['Authorization'] = 'Bearer ' + access_token

      resources.each do |klass|
        klass.site = klass.site_format % "#{self.server}rest-1.v1/Data/"
      end
    end

    def resources
      @resources ||= []
    end
  end

  class Base < ActiveResource::Base
    self.format = NokogiriXmlFormat

    %w(site).each do |attr|

      define_method(attr) do
        Thread.current["active_resource.base.#{attr}"]
      end

      define_method("#{attr}=") do |val|
        Thread.current["active_resource.base.#{attr}"] = val
      end
    end

    def self.inherited(base)
      VersiononeAPI.resources << base
      class << base
        attr_accessor :site_format
      end
      base.site_format = '%s'
      super
    end


    def parse_status_code(status)
      status = status.to_s
      unless status.nil?
        case status
          when 'done'
            "StoryStatus:135"
          when 'in_progress'
            "StoryStatus:134"
          else
            "StoryStatus:133"
        end
      end
    end

    def encode(options={})
        updated_fields = self.class.updated_fields
      val = ''
       val += '<Asset>'
      if updated_fields.nil?
        attributes.each_pair do |key, value|
          if(key == 'project_id')
            val += "<Relation name='Scope' act='set'><Asset idref='Scope:#{value}' /></Relation>"
          elsif key == 'parent' && !value.nil? && value != ''
            val += "<Relation name='Super' act='set'><Asset idref='#{value}' /></Relation>"
          elsif !getUpdateableFieldName(key).nil?
            if key == 'status'
              unless value.to_s == :unstarted.to_s || value.nil? || self.issuetype.downcase == "epic"

                status = parse_status_code(value)
                val += "<Attribute name='Status' act='set'>#{xml_encode(status, :text)}</Attribute>"
              end
            else
                val += "<Attribute name='#{getUpdateableFieldName(key)}' act='set'>#{xml_encode(value, :text)}</Attribute>"
            end
          end

        end
      elsif updated_fields.any?
        attributes.each_pair do |key, value|
          if(key == 'project_id')
            val += "<Relation name='Scope' act='set'><Asset idref='Scope:#{value}' /></Relation>"
          # elsif key == 'parent' && !value.nil? && value != ''  <- Not modifying hierarchy
          #   val += "<Relation name='Super' act='set'><Asset idref='#{value}' /></Relation>"
          elsif !getUpdateableFieldName(key).nil? && updated_fields.include?(key)
            if key == 'status'
              unless value.to_s == :unstarted.to_s  || value.nil? || self.issuetype.downcase == "epic"
                status = parse_status_code(value)
                val += "<Attribute name='Status' act='set'>#{xml_encode(status, :text)}</Attribute>"
              end
            else
              val += "<Attribute name='#{getUpdateableFieldName(key)}' act='set'>#{xml_encode(value, :text)}</Attribute>"
            end
          end

        end

      end

      val += '</Asset>'
      updated_fields = self.class.updated_fields = nil

      val
    end

    def xml_encode(value, encode_constraints)
      if value.is_a? String
        value.encode(:xml => encode_constraints)
      else
        value
      end
    end

    def getUpdateableFieldName(key)
      nil
    end

    def self.instantiate_collection(collection, original_params = {}, prefix_options = {})
      objects = collection.find {|x| x.has_key? :Assets }[:Assets]
      objects[:children].collect! { |record| instantiate_record(record, prefix_options) }
    end

    def update

      connection.post(update_path, encode, self.class.headers).tap do |response|
        load_attributes_from_response(response)
      end
    end

    def update_path
      element_path(prefix_options)
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

    # this provides the default search criteria for a good number
    # of our queries.
    #
    # :where => "Scope='Scope:#{id}'"
    #     filters the query to only get the stories
    #     that are relevant to this particular project
    #     https://community.versionone.com/Developers/Developer-Library/Documentation/API/Queries/where
    # :sel => VersiononeAPI::Issue::ISSUE_SELECTION_FIELDS
    #     selects only the fields that we care about
    #     https://community.versionone.com/Developers/Developer-Library/Documentation/API/Queries/select
    def self.query_params_for_scope(id)
      {
          :params => {
              :where => "Scope='Scope:#{id}'",
              :sel => VersiononeAPI::Issue::ISSUE_SELECTION_FIELDS
          }
      }
    end
    def self.epic_query_params_for_scope(id)
      {
          :params => {
              :where => "Scope='Scope:#{id}'",
              :sel => VersiononeAPI::Issue::EPIC_SELECTION_FIELDS
          }
      }
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
        "#{site.path}Scope#{selection_query_string(query_options, false)}"
      end

      def self.element_path(id, prefix_options = {}, query_options = nil)
        self.extended_element_path(id, false, prefix_options, query_options)
      end

      def self.extended_element_path(id, is_post, prefix_options = {}, query_options = nil)
        #id format is "resource_name:id", but element_path just needs the id, without the resource_name.
        scope_id = id.to_s
        scope_id.gsub!("Scope:", "")
        prefix_options, query_options = split_options(prefix_options) if query_options.nil?
        "#{site.path}Scope/#{ERB::Util.url_encode scope_id}#{selection_query_string(query_options, is_post)}"
      end


      def self.instantiate_record(record, prefix_option = {})
        object = record
        object = object.first if object.kind_of? Array

        simplified = {:id => find_asset_id(object, 'Scope'),
         :description => find_text_attribute(object, 'Description'),
         :created_at => find_text_attribute(object, 'CreateDateUTC').try { |str| DateTime.parse(str) unless str.nil? or str.empty?},
         :updated_at => find_text_attribute(object, 'ChangeDateUTC').try { |str| DateTime.parse(str) unless str.nil? or str.empty?},
         :name => find_text_attribute(object, 'Name'),
         :owner => find_text_attribute(object, 'Owner.Name'),
         :child_project_ids => find_relation_ids(object, 'Children', 'Scope')}

        super(simplified, prefix_option)
      end

      SCOPE_SELECTION_QUERY_OPTIONS = 'sel=Name,Description,Owner.Name,CreateDateUTC,ChangeDateUTC,Children'

      UPDATEABLE_FIELDS = {
          'name' => 'Name',
          'description' => 'Description',
          #'owner' => 'Owner.Name'
      }

      def update_path
        self.class.extended_element_path(to_param, true, prefix_options)
      end

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

      private

      def self.selection_query_string(options, is_post)
        if is_post
          query_str = query_string(options)
        else
          options =  (options.nil? || options.empty?) ? '' : "&#{options.to_query}"

          query_str = "?#{SCOPE_SELECTION_QUERY_OPTIONS}#{options}"
        end
        query_str
      end

  end

  class Issue < Base
    extend HasAssets
    before_save :save_routing
    before_destroy :save_routing

    class << self; attr_accessor :test, :rest_uri,:route, :updated_fields end
    @test = 8

    @rest_uri = nil
    @route = nil
    @updated_fields = nil

    def self.collection_path(prefix_options = {}, query_options = nil)
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?
      if @route.nil?
        return "#{site.path}Story#{query_string(query_options)}"
      else
        route = @route
        route[0] = route[0].capitalize
        return "#{site.path}#{route}#{query_string(query_options)}"
      end

    end

    def self.element_path(id, prefix_options = {}, query_options = nil)
      scope_id = id.to_s
      scope_id.gsub!("Story:", "")
      prefix_options, query_options = split_options(prefix_options) if query_options.nil?

      if !@rest_uri.nil?
        return "#{@rest_uri[0]}#{query_string(query_options)}"
      elsif !@route.nil?
        route = @route
        route[0] = route[0].capitalize
        return "#{site.path}#{route}/#{ERB::Util.url_encode scope_id}#{query_string(query_options)}"
      else
        return "#{site.path}Story/#{ERB::Util.url_encode scope_id}#{query_string(query_options)}"
      end
    end

    def self.instantiate_record(record, prefix_option = {})
      object = record
      object = object.first if object.kind_of? Array

      asset_id = find_asset_id(object, 'Story')
      asset_id = find_asset_id(object, 'Epic') if asset_id.nil? || asset_id == 0
      issuetype = find_text_attribute(object, 'AssetType')

      parent = find_relation_id(object, 'Super', 'Epic')
      parent = find_relation_id(object, 'Super', 'Story') if parent.nil?

      simplified = {
          :id => asset_id,
          :full_id => "#{issuetype}:#{asset_id}",
          :href => href_from_id(issuetype ,asset_id),
          :rest_uri => find_asset_href(object),
          :title => find_text_attribute(object, 'Name'),
          :description => find_text_attribute(object, 'Description'),
          :requestor => find_text_attribute(object, 'RequestedBy'),
          :project_id => find_relation_id(object, 'Scope', 'Scope'),
          :priority => find_text_attribute(object, 'Priority.Name'),
          :status => find_text_attribute(object, 'Status.Name').try {|status| status.parameterize.underscore.to_sym},
          :assignee => find_value_attribute(object, 'Owners.Name') ,
          :asset_state => find_text_attribute(object, 'AssetState').try { |state| parse_asset_state(state)  },
          :issuetype => issuetype.downcase,
          :iteration_id => find_relation_id(object, 'Timebox', 'Timebox'),
          :created_at => find_text_attribute(object, 'CreateDateUTC').try { |str| DateTime.parse(str) unless str.nil? or str.empty?},
          :updated_at => find_text_attribute(object, 'ChangeDateUTC').try { |str| DateTime.parse(str) unless str.nil? or str.empty?},
          :parent => parent,
          :estimate => find_text_attribute(object, 'Estimate') #.try {|estimate| estimate.to_i }
          }
      super(simplified, prefix_option)
    end

    # parse the asset state (which is returned as a number) into a symbol
    # values can be found here:
    # https://community.versionone.com/Developers/Developer-Library/Concepts/Asset_State
    def self.parse_asset_state(state)
      case state
        when '0'
          :future
        when '64'
          :active
        when '128'
          :closed
        when '200'
          :template
        when '208'
          :broken_down
        when '255'
          :deleted
        else
          :unknown
      end
    end


    def self.href_from_id(issuetype, id )
      route = issuetype
      route[0] = route[0].capitalize
    
     "#{VersiononeAPI.server}#{route.downcase}.mvc/Summary?oidToken=#{route}%3A#{id}"
    end

    # Takes a response from a typical create post and pulls the ID out
    def id_from_response(response)
      decoded = self.class.format.decode(response.body).first
      self.class.find_asset_id(decoded, 'Story')
    end

    ISSUE_SELECTION_FIELDS = 'Name,Description,RequestedBy,Scope,Priority.Name,Status.Name,Timebox,Owners.Name,AssetState,AssetType,Super,CreateDateUTC,ChangeDateUTC,Estimate'

    EPIC_SELECTION_FIELDS = 'Name,Description,RequestedBy,Scope,Priority.Name,Status.Name,Timebox,Owners.Name,AssetState,AssetType,Super,CreateDateUTC,ChangeDateUTC'

    UPDATEABLE_FIELDS = {
        'title' => 'Name',
        'description' => 'Description',
        #'requestor' => 'RequestedBy',
        #'priority' => 'Priority.Name',
        'status' => 'Status.Name',
        'estimate' => 'Estimate'
        #'assignee' => 'Owners.Name'
    }

    def getUpdateableFieldName(key)
      UPDATEABLE_FIELDS[key]
    end

    def self.find_epics (id)
      @route = "Epic"
      find(:all, epic_query_params_for_scope(id))
    end

    def self.find_stories (id)
      @route = "Story"
      find(:all, query_params_for_scope(id))
    end

    def self.find_epic_by_id (project_id, epic_id)
      @route = "Epic"
      find(:all, epic_query_params_for_scope(project_id))

    #   find(epic_id, epic_query_params_for_scope(project_id))
    end

    def self.find_story_by_id (project_id, story_id)
      @route = "Story"

      find(story_id, query_params_for_scope(project_id))
    end

    def self.set_route route
      @route = route
    end

    def self.get_route
      @route
    end

    def self.set_rest_uri rest_uri
      @rest_uri = rest_uri
    end

    def self.get_rest_uri
      @rest_uri
    end

    def self.set_updated_fields fields
      @updated_fields = fields
    end


    def save_routing
      issuetype = rest_uri = nil
      issuetype = self.issuetype if self.issuetype?
      rest_uri = self.rest_uri if self.rest_uri?
      self.class.set_route issuetype
      self.class.set_rest_uri rest_uri
    end

    def destroy
      run_callbacks :destroy do
        prefix_options[:op] = 'Delete'
        path = element_path
        connection.post(path, nil, self.class.headers)
      end
    end
  end
end
