require 'data_helper'
require 'rack/test'

RSpec.configure do |c|
  c.include Rack::Test::Methods
end

def session
  last_request.session
end

def env_for(params)
  { 'rack.session' => params[:session] }
end

require_relative './rack/mock_response'

