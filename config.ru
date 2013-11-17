base = File.dirname(__FILE__)
require File.join(base, 'lib', 'config')
require File.join(base, 'lib', 'models')

require File.join(base, 'apps', 'web', 'app')

map '/' do
  run Evercam::WebApp
end

