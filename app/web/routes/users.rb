module Evercam
  class WebApp

    get '/users/:username' do |username|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user
      erb 'users/view'.to_sym
    end

  end
end

