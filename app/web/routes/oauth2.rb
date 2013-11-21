module Evercam
  class WebApp

    get '/oauth2/authorize' do
      with_user do |user|
        erb 'oauth2/authorize'.to_sym
      end
    end

    post '/oauth2/authorize' do
    end

  end
end

