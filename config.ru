require 'bundler'
Bundler.require(:default)

base = File.dirname(__FILE__)
require File.join(base, 'lib', 'config')
require File.join(base, 'lib', 'models')

require File.join(base, 'apps', 'api', 'v1')
require File.join(base, 'apps', 'web', 'app')

map '/v1' do
  run Evercam::APIv1
end

map '/' do
  run Evercam::WebApp
end

