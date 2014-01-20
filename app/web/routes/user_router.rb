require_relative "./web_router"

module Evercam
  class WebUserRouter < WebRouter

    get '/users/:username' do |username|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      erb 'users/view'.to_sym

    end

    get '/users/:username/cameras/:camera' do |username, camera|
      erb 'users/cameras/view'.to_sym
    end

  end
end
