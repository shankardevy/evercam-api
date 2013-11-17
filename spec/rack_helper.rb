require 'data_helper'
require 'rack/test'

ENV['RACK_ENV'] ||= ENV['SPEC_ENV']

RSpec.configure do |c|
  c.include Rack::Test::Methods
end

def session
  last_request.session
end

def env_for(params)
  { 'rack.session' => params[:session] }
end

require 'nokogiri'
require_relative './rack/mock_response'

