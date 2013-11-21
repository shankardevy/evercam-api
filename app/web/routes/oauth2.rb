module Evercam
  class WebApp

    get '/oauth2/error' do
    end

    get '/oauth2/authorize' do
      with_user do |user|
        req = OAuth2::Authorize.new(params)

        unless req.valid?
          redirect req.uri if req.redirect?
          redirect '/oauth2/error', error: req.error
        end

        redirect req.uri
      end
    end

    post '/oauth2/authorize' do
    end

  end
end

