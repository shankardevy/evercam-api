require_relative "./web_router"

module Evercam
  class WebRootRouter < WebRouter


    get '/' do
      erb 'index'.to_sym
    end

    get %r{/oauth2*} do
      redirect request.url.sub(/api\./, 'dashboard.'), 301
    end

  end
end

