ENV['SPEC_ENV'] ||= 'test'

def require_app(name)
  require_relative "../apps/#{name}"
end

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
end

