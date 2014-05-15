require 'bundler'
require 'rack/rewrite'
require 'evercam_misc'
require 'sequel'

# Establish a connection to the database.
db = Sequel.connect(Evercam::Config[:database])

Bundler.require(:default)

# This monkeypatch is needed to ensure the X-Frame-Options header is
# never set by rack-protection.
module Rack
  module Protection
    class FrameOptions < Base
      def call(env)
        status, headers, body = @app.call(env)
        [status, headers, body]
      end
    end
  end
end

base = File.dirname(__FILE__)
['api/v1', 'web/app'].each do |app|
  require File.join(base, 'app', app)
end

# Set up Airbrake.
Airbrake.configure do |config|
   config.api_key = Evercam::Config[:airbrake][:api_key]
end

map '/v1' do

  # setup ssl requirements
  use Rack::SslEnforcer,
    Evercam::Config[:api][:ssl]

  # allow requests from anywhere
  use Rack::Cors do
    allow do
      origins '*'
      resource '*',
        :headers => :any,
        :methods => [:get, :post, :put, :delete, :options, :patch]
    end
  end

  # ensure cookies work across subdomains
  use Rack::Session::Cookie,
    Evercam::Config[:cookies]

  run Evercam::APIv1

end

map '/' do
  # setup ssl requirements
  use Rack::SslEnforcer,
      Evercam::Config[:api][:ssl]

  run Evercam::WebApp
end

