require 'bundler'
require 'rack/rewrite'
Bundler.require(:default)

use Rack::Rewrite do
  if Sinatra::Base.production?
    r301 %r{.*}, 'https://www.evercam.io$&', :if => Proc.new {|rack_env|
      rack_env['SERVER_NAME'] != 'www.evercam.io'
    }
  end
end

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

