require_relative '../../lib/oauth2'

module Evercam
  class WebApp < Sinatra::Base

    include WebErrors
    set :raise_errors, false
    set :show_exceptions, false

    configure do
      set :erb, layout: 'layouts/default'.to_sym
    end

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    register Sinatra::Flash
    helpers Sinatra::RedirectWithFlash

    register Sinatra::Partial
    set :partial_template_engine, :erb

    error NotFoundError do
      status 404
      erb 'errors/404'.to_sym
    end

    error BadRequestError do
      status 400
      @message = env['sinatra.error'].message
      erb 'errors/400'.to_sym
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

['root', 'oauth2', 'login', 'docs'].each do |rt|
  require_relative "./routes/#{rt}"
end

