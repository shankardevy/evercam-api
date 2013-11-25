base = File.dirname(__FILE__)

['rack/cors'].each do |gem|
  require gem
end

['config', 'errors', 'models', 'actors', 'mailers'].each do |lib|
  require File.join(base, 'lib', lib)
end

['api/v1', 'web/app'].each do |app|
  require File.join(base, 'app', app)
end

map '/v1' do

  use Rack::Cors do
    allow do
      origins '*'
      resource '*'
    end
  end

  run Evercam::APIv1

end

map '/' do
  run Evercam::WebApp
end

