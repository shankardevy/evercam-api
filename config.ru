require 'bundler'
Bundler.require(:default)

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
        :methods => [:get, :post, :put, :options]
    end
  end

  # ensure cookies work across subdomains
  use Rack::Session::Cookie,
    Evercam::Config[:cookies]

  run Evercam::APIv1

end

require 'sidekiq/web'
map '/sidekiq' do
  run Sidekiq::Web
end

map '/' do
  run Evercam::WebApp
end

