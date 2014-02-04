require_relative "./web_router"
require_relative "../../../lib/models"

module Evercam
  class WebUserRouter < WebRouter

    get '/users/:username' do |username|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      @models = Firmware.to_hash(:id, :name)
      @cameras = Camera.where(:owner_id => @user.id)
      erb 'users/user_view'.to_sym

    end

    get '/users/:username/cameras/:camera' do |username, camera|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      @models = Firmware.to_hash(:id, :name)
      @camera = Camera.by_exid(camera)
      raise NotFoundError, 'Camera does not exist' unless @camera
      erb 'users/cameras/camera_view'.to_sym
    end

  end
end
