ENV['EVERCAM_ENV'] ||= 'test'

require 'bundler'
Bundler.require(:default, :test)

# code coverage
SimpleCov.start do
  add_filter '/spec/'
end

require_relative './matchers'
require_relative '../lib/config'
require_relative '../lib/errors'

def require_app(name)
  require_relative "../app/#{name}"
end

def require_lib(name)
  require_relative "../lib/#{name}"
end

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
  c.filter_run :focus => true
  c.filter_run_excluding skip: true
  c.run_all_when_everything_filtered = true
  c.mock_framework = :mocha
  c.fail_fast = true if ENV['FAIL_FAST']
end

# fake out sidekiq redis
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Stubbed requests
require 'webmock/rspec'

