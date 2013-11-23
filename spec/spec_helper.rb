ENV['EVERCAM_ENV'] ||= 'test'

require_relative '../lib/config'
require_relative '../lib/errors'
Bundler.require(:default, :test)

def require_app(name)
  require_relative "../app/#{name}"
end

def require_lib(name)
  require_relative "../lib/#{name}"
end

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
  c.filter_run_excluding skip: true
  c.mock_framework = :mocha
end

