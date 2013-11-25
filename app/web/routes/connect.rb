module Evercam
  class WebApp

    get '/connect' do
      erb 'connect/index'.to_sym
    end

  end
end

