require_relative '../../lib/config'
require_relative '../../lib/models'
require_relative '../../lib/errors'
require_relative '../../lib/oauth2'

module Evercam
  class WebApp < Sinatra::Base

    include WebErrors
    set :raise_errors, false
    set :show_exceptions, false

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    register Sinatra::Flash
    helpers Sinatra::RedirectWithFlash

    error BadRequestError do
      redirect '/errors/400', error: env['sinatra.error'].message
    end

    def with_user
      uid = session[:user]
      usr = uid ? User[uid] : nil

      uri = CGI.escape(request.fullpath)
      redirect "/login?rt=#{uri}" unless usr

      yield usr
    end

  end
end

require_relative './routes/root'
require_relative './routes/oauth2'
require_relative './routes/login'

