require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "TaskMapper::Provider::Versionone::Ticket" do
  before(:all) do
    headers = headers_for('admin', 'admin')

    SCOPE_SELECTION_QUERY = 'sel=Name,Description,Owner.Name,CreateDateUTC,ChangeDateUTC,Children'
    SELECTION_QUERY = 'sel=Name%2CDescription%2CRequestedBy%2CScope%2CPriority.Name%2CStatus.Name%2COwners.Name%2CAssetState%2CAssetType%2CSuper%2CCreateDateUTC%2CChangeDateUTC%2CEstimate'

    ActiveResource::HttpMock.respond_to do |mock|
      mock.get "/Trial30/rest-1.v1/Data/Scope/1009?#{SCOPE_SELECTION_QUERY}", headers, fixture_for('Scope1009'), 200
      mock.get "/Trial30/rest-1.v1/Data/Scope/1010?#{SCOPE_SELECTION_QUERY}", headers, fixture_for('Scope1010'), 200
      mock.get "/Trial30/rest-1.v1/Data/Scope/1132?#{SCOPE_SELECTION_QUERY}", headers, fixture_for('Scope1132'), 200
      mock.get "/Trial30/rest-1.v1/Data/Scope/1164?#{SCOPE_SELECTION_QUERY}", headers, fixture_for('Scope1164'), 200
      mock.get "/Trial30/rest-1.v1/Data/Scope/1610?#{SCOPE_SELECTION_QUERY}", headers, fixture_for('Scope1610'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1009%27", headers, fixture_for('Stories'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1010%27", headers, fixture_for('Stories1010'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1132%27", headers, fixture_for('Stories1132'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1164%27", headers, fixture_for('Stories1164'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1610%27", headers, fixture_for('Stories1610'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story/1013?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1009%27", headers, fixture_for('Story1013'), 200
      mock.get "/Trial30/rest-1.v1/Data/Story/1014?#{SELECTION_QUERY}&where=Scope%3D%27Scope%3A1009%27", headers, fixture_for('Story1014'), 200
    end

    # Updated story
    updateRequest = ActiveResource::Request.new(:post,
                                          path = '/Trial30/rest-1.v1/Data/Story/1013',
                                          body = "<Asset><Attribute name='Name' act='set'>Hello World</Attribute></Asset>",
                                          request_headers = post_headers_for('admin', 'admin'))
    updateResponse = ActiveResource::Response.new(body = fixture_for('StoryTitleUpdate'),
                                            status = 200,
                                            {})
    ActiveResource::HttpMock.responses << [updateRequest, updateResponse]

    # New Story
    createRequest = ActiveResource::Request.new(:post,
                                                  path = '/Trial30/rest-1.v1/Data/Story',
                                                  body = "<Asset><Attribute name='Name' act='set'>Ticket #12</Attribute><Attribute name='Description' act='set'>Body</Attribute><Relation name='Scope' act='set'><Asset idref='Scope:1009' /></Relation></Asset>",
                                                  request_headers = post_headers_for('admin', 'admin'))

    createResponse = ActiveResource::Response.new(body = fixture_for('NewStory'),
                                                  status = 200,
                                                  {})
    ActiveResource::HttpMock.responses << [createRequest, createResponse]



    @project_id = 1009
    @ticket_id = 1013
  end

  before(:each) do
    @taskmapper = TaskMapper.new(:versionone, :server => 'http://server/Trial30', :username => 'admin', :password => 'admin')
    @project = @taskmapper.project(@project_id)
    @klass = TaskMapper::Provider::Versionone::Ticket
  end

  it "should be able to load all tickets" do
    @project.tickets.should be_an_instance_of(Array)
    @project.tickets.first.should be_an_instance_of(@klass)
  end

  it "should be able to load all tickets based on an array of ids" do
    @tickets = @project.tickets([@ticket_id])
    @tickets.should be_an_instance_of(Array)
    @tickets.first.should be_an_instance_of(@klass)
    @tickets.first.id.should == @ticket_id
  end

  it "should be able to load all tickets based on attributes" do
    @tickets = @project.tickets(:id => @ticket_id)
    @tickets.should be_an_instance_of(Array)
    @tickets.first.should be_an_instance_of(@klass)
    @tickets.first.id.should == @ticket_id
    @tickets.first.url.should == "http://server/Trial30/story.mvc/Summary?oidToken=Story%3A#{@ticket_id}"
  end

  it "should return the ticket class" do
    @project.ticket.should == @klass
  end

  it "should be able to load a single ticket" do
    @ticket = @project.ticket(@ticket_id)
    @ticket.should be_an_instance_of(@klass)
    @ticket.id.should == @ticket_id
  end

  it "should be able to load a single ticket based on attributes" do
    @ticket = @project.ticket(:id => @ticket_id)
    @ticket.should be_an_instance_of(@klass)
    @ticket.id.should == @ticket_id
  end

  it "should be able to update and save a ticket" do
    @ticket = @project.ticket(@ticket_id)
    #@ticket.save.should == nil
    @ticket.description = 'hello'
    @ticket.status = :in_progress
    @ticket.save.should == true
  end

  it "should be able to update a ticket to add a label and save the ticket" do
    pending("using posts in the api access")
    @ticket = @project.ticket(@ticket_id)
    @ticket.labels = 'sample label'
    @ticket.labels.should == 'sample label'
    @ticket.save.should == true
  end

  it "should be able to create a ticket" do
    @ticket = @project.ticket!(:title => 'Ticket #12', :description => 'Body', :issuetype => "Story")
    @ticket.should be_an_instance_of(@klass)
    @ticket.id.should == 1072
    @ticket.url.should == "http://server/Trial30/story.mvc/Summary?oidToken=Story%3A1072"
    expect(@ticket.save).to be_truthy

  end

  it "should be able to load all tickets based on attributes using updated_at field" do
    @ticket = @project.ticket(@ticket_id)
    tickets = @project.tickets(:updated_at => @ticket.updated_at)
    tickets.should be_an_instance_of(Array)
    tickets.first.should be_an_instance_of(@klass)
  end

  it "should be able to load all tickets based on attributes using created_at field" do
    @ticket = @project.ticket(@ticket_id)
    tickets = @project.tickets(:created_at => @ticket.created_at)
    tickets.should be_an_instance_of(Array)
    tickets.first.should be_an_instance_of(@klass)
  end

  it "should return the requested_by field" do
    @ticket = @project.ticket(@ticket_id)
    @ticket.requestor.should == 'joe.user@example.com'
  end

  it "should return the status field" do
    @ticket = @project.ticket(@ticket_id)
    @ticket.status_name.should == :accepted
  end

  it "should generate the story href" do
    @ticket = @project.ticket(@ticket_id)

    @ticket.href.should == 'http://server/Trial30/story.mvc/Summary?oidToken=Story%3A1013'
  end

  describe 'projects with sub-projects' do
    before do
      @project = @taskmapper.project(1010)
    end

    it 'should get all the tickets in every child as well.' do
      tickets = @project.tickets()

      tickets.length.should == 3
    end
  end

  describe 'parsing asset state' do
    it 'should parse closed' do
      @ticket = @project.ticket(@ticket_id)
      @ticket.asset_state.should == :closed
    end

    it 'should parse active' do
      @ticket = @project.ticket(1014)
      @ticket.asset_state.should == :active
    end

  end

  describe 'status' do
    it 'should be :completed if the asset_state is :closed' do
      @klass.new(:asset_state => :closed).status.should == :completed
      @klass.new(:asset_state => :closed, :status_name => :future).status.should == :completed
    end

    it 'should be :started if asset_state is not :closed or :deleted and it has a status' do
      @klass.new(asset_state: :active, status_name: :future).status.should == :started
      @klass.new(asset_state: :active, status_name: :in_progress).status.should == :started
      @klass.new(asset_state: :active, status_name: :done).status.should == :started
      @klass.new(asset_state: :active, status_name: :accepted).status.should == :started

      # the future class here is a thought exercise, as I can't see a way
      # to set the asset state to future in the slightest.
      @klass.new(asset_state: :future, status_name: :future).status.should == :started
      @klass.new(asset_state: :future, status_name: :in_progress).status.should == :started
      @klass.new(asset_state: :future, status_name: :done).status.should == :started
      @klass.new(asset_state: :future, status_name: :accepted).status.should == :started
    end

    it 'should be :unstarted if not :closed or :deleted and no status' do
      @klass.new(asset_state: :future).status.should == :unstarted
      @klass.new(asset_state: :active).status.should == :unstarted
      @klass.new(asset_state: :future, status_name: '').status.should == :unstarted
      @klass.new(asset_state: :active, status_name: '').status.should == :unstarted
    end

    it 'should be :unstarted if :deleted' do
      @klass.new(asset_state: :deleted, status_name: :future).status.should == :unstarted
      @klass.new(asset_state: :deleted, status_name: :in_progress).status.should == :unstarted
      @klass.new(asset_state: :deleted, status_name: :done).status.should == :unstarted
      @klass.new(asset_state: :deleted, status_name: :accepted).status.should == :unstarted
    end
  end

  it "should be able to update a ticket" do
    @ticket = @project.ticket(@ticket_id)
    @ticket.title = "Hello World"
    @ticket.save.should be_true
  end

  it "should have all contract fields for tickets" do
    @ticket = @project.ticket(@ticket_id)
    @ticket.title.should_not be_nil
    @ticket.description.should_not be_nil
    @ticket.status_name.should_not be_nil
    @ticket.priority.should_not be_nil
    @ticket.resolution.should_not be_nil
    @ticket.created_at.should_not be_nil
    @ticket.updated_at.should_not be_nil
    @ticket.assignee.should_not be_nil
    @ticket.requestor.should_not be_nil
    @ticket.project_id.should_not be_nil
  end

end
