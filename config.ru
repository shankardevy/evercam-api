require 'bundler'
require 'rack/rewrite'
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

#use Rack::Rewrite do
#  if Sinatra::Base.production?
#    r301 %r{.*}, 'https://dashboard.evercam.io$&', :if => Proc.new {|rack_env|
#      rack_env['SERVER_NAME'] != 'dashboard.evercam.io' and rack_env['SERVER_NAME'] != 'api.evercam.io'
#    }
#  end
#end

base = File.dirname(__FILE__)
['api/v1', 'web/app'].each do |app|
  require File.join(base, 'app', app)
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
        :methods => [:get, :post, :put, :delete, :options]
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

