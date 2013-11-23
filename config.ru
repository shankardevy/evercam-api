base = File.dirname(__FILE__)

['config', 'errors', 'models'].each do |lib|
  require File.join(base, 'lib', lib)
end

['api/v1', 'web/app'].each do |app|
  require File.join(base, 'app', app)
end

map '/v1' do
  run Evercam::APIv1
end

map '/' do
  run Evercam::WebApp
end

