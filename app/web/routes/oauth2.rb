module Evercam
  class WebApp

    get '/oauth2/error' do
    end

    get '/oauth2/authorize' do
      with_user do |user|
        req = OAuth2::Authorize.new(user, params)

        redirect req.redirect_to if req.redirect?
        raise BadRequestError, req.error unless req.valid?

        erb 'oauth2/authorize'.to_sym
      end
    end

    post '/oauth2/authorize' do
    end

  end
end
