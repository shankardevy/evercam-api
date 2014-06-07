ENV['EVERCAM_ENV'] ||= 'test'

require 'evercam_misc'
require 'sequel'
db = Sequel.connect(Evercam::Config[:database])

require 'minitest/autorun'

require 'bundler'
Bundler.require(:default, :test)

# code coverage
SimpleCov.start do
  add_filter '/spec/'
end

require_relative './matchers'

def require_app(name)
  require_relative "../app/#{name}"
end

def require_lib(name)
  require_relative "../lib/#{name}"
end

LogJam.configure({
  # turn the noise down to separate problems from messages
  loggers: { default: true, level: ENV['LOG'] || 'INFO' }
})

RSpec.configure do |c|
  c.expect_with :stdlib, :rspec
  c.filter_run :focus => true
  c.filter_run_excluding skip: true
  c.run_all_when_everything_filtered = true
  c.mock_framework = :mocha
  c.fail_fast = true if ENV['FAIL_FAST']

  c.after(:suite) do
    DatabaseCleaner.clean_with :truncation, except: %w[spatial_ref_sys]
  end

  c.before :each do
    Typhoeus::Expectation.clear
    #Stub intercom.io requests
    stub_request(:get, /.*api.intercom.io.*/).
      to_return(:status => 200, :body => "", :headers => {})
  end
end

# fake out sidekiq redis
require 'sidekiq/testing'
Sidekiq::Testing.fake!

# Stubbed requests
require 'webmock/rspec'

# Set up Airbrake.
require 'airbrake'
Airbrake.configure do |config|
  config.api_key = Evercam::Config[:airbrake][:api_key]
  config.environment_name = (ENV['RACK_ENV'] || 'test')
end

