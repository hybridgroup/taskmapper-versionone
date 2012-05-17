$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'taskmapper'
require 'rspec'
require 'taskmapper-versionone'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each {|f| require f}

RSpec.configure do |config|
  config.color_enabled = true
end

def fixture_for(name, format = 'xml')
  File.read(File.dirname(__FILE__) + "/fixtures/#{name}.#{format}")
end
