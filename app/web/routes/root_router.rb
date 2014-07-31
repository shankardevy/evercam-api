require_relative "./web_router"

module Evercam
  class WebRootRouter < WebRouter


    get '/' do
      redirect 'http://www.evercam.io/develop/'
    end

    get %r{/oauth2*} do
      redirect request.url.sub(/api\./, 'dashboard.'), 301
    end

  end
end

