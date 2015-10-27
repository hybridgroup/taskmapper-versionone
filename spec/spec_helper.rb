$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'taskmapper'
require 'rspec'
require 'taskmapper-versionone'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.color = true
end

def headers_for(username, password)
  return {
      'Authorization' => "Basic #{Base64.encode64(username + ':' + password)}".strip,
      'Accept' => 'application/xml'
  }
  end

def headers_for_access_token(access_token)
  return {
      'Authorization' => "Bearer #{access_token}".strip,
      'Accept' => 'application/xml'
  }
end

def post_headers_for_access_token(access_token)
  return {
      'Authorization' => "Bearer #{access_token}".strip,
      'Content-Type' => 'application/xml'
  }
end

def post_headers_for(username, password)
  return {
      'Authorization' => "Basic #{Base64.encode64(username + ':' + password)}".strip,
      'Content-Type' => 'application/xml'
  }
end

def fixture_for(name, format = 'xml')
  File.read(File.dirname(__FILE__) + "/fixtures/#{name}.#{format}")
end
