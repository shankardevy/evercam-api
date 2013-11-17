ENV['EVERCAM_ENV'] ||= 'test'
require_relative '../lib/config'

def require_app(name)
  require_relative "../apps/#{name}"
end

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
end

