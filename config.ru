require 'bundler'
require 'rack/rewrite'
require 'dalli'
require 'evercam_misc'
require 'sequel'
require 'sidekiq/web'

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
   config.environment_name = (ENV['RACK_ENV'] || 'development')
   config.ignore << "Evercam::CameraOfflineError"
   config.ignore << "Evercam::AuthorizationError"
   config.ignore << "Evercam::NotFoundError"
end

Geocoder.configure(
  :timeout => 5,
  :ip_lookup => :telize
)

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

  # Bring in Airbrake.
  use Airbrake::Rack

  # Enable gzip
  use Rack::Deflater

  run Evercam::APIv1

end

map '/' do
  # setup ssl requirements
  use Rack::SslEnforcer,
      Evercam::Config[:api][:ssl]

  run Evercam::WebApp
end

map '/sidekiq' do
  use Rack::SslEnforcer,
      Evercam::Config[:api][:ssl]

  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username == 'sidekiq' && password == 'mehcam'
  end

  run Sidekiq::Web
end
