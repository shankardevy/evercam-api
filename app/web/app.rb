require_relative '../../lib/config'
require_relative '../../lib/models'
require_relative '../../lib/errors'
require_relative '../../lib/oauth2'

module Evercam
  class WebApp < Sinatra::Base

    include WebErrors

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    register Sinatra::Flash

    def with_user
      uid = session[:user]
      usr = uid ? User[uid] : nil

      uri = CGI.escape(request.fullpath)
      redirect "/login?rt=#{uri}" unless usr

      yield usr
    end

  end
end

require_relative './routes/login'
require_relative './routes/oauth2'
require_relative './routes/jobs'

