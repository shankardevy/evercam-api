require_relative '../../lib/config'
require_relative '../../lib/models'
require_relative '../../lib/errors'

module Evercam
  class WebApp < Sinatra::Base

    include WebErrors

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    register Sinatra::Flash

  end
end

require_relative './routes/login'
require_relative './routes/oauth2'

