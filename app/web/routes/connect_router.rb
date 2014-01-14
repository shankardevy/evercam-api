require_relative "./web_router"

module Evercam
  class WebConnectRouter < WebRouter

    get '/connect' do
      erb 'connect/index'.to_sym
    end

  end
end

