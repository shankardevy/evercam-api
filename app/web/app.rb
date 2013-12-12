['config',
 'errors',
 'models',
 'actors',
 'mailers',
 'oauth2'
].each { |f| require_relative "../../lib/#{f}" }

['helpers/form_helpers'
].each { |f| require_relative "./#{f}" }

module Evercam
  class WebApp < Sinatra::Base

    include WebErrors
    set :raise_errors, false
    set :show_exceptions, false

    # set cookies for three years
    set :cookie_options do
      { expires: Time.now + 3 * 365 * 24 * 60 * 60 }
    end

    configure do
      set :erb, layout: 'layouts/default'.to_sym
    end

    # ensure cookies work across subdomains
    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    # enable flash hash
    register Sinatra::Flash

    # enable partial helpers and default to erb
    register Sinatra::Partial
    set :partial_template_engine, :erb

    # handle 404 like a pro...
    error NotFoundError, Sinatra::NotFound do
      error_response(404)
    end

    # handle a 400 with a nice error
    error BadRequestError do
      error_response(400)
    end

    helpers do
      def error_response(code)
        status code
        @error = env['sinatra.error']
        erb "errors/#{code}".to_sym
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

    helpers Sinatra::Cookies
    helpers Sinatra::RedirectWithFlash
    helpers Evercam::FormHelpers

  end
end

['routes/root',
 'routes/oauth2',
 'routes/signup',
 'routes/login',
 'routes/connect',
 'routes/docs'
].each { |f| require_relative "./#{f}" }

