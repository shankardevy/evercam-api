require_relative '../../lib/actors'
require_relative '../../lib/mailers'
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

    def curr_user
      uid = session[:user]
      uid ? User[uid] : nil
    end

    def with_user
      uri = CGI.escape(request.fullpath)
      redirect "/login?rt=#{uri}" unless curr_user
      yield curr_user
    end

  end
end

['root', 'oauth2', 'login', 'docs', 'connect'].each do |rt|
  require_relative "./routes/#{rt}"
end

