module Evercam
  class WebApp

    get '/oauth2/authorize' do
      erb 'oauth2/authorize'.to_sym
    end

    post '/oauth2/authorize' do
    end

  end
end

