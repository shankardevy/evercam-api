module Evercam
  class WebApp < Sinatra::Base

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    register Sinatra::Flash

  end
end

require_relative './routes/login'

