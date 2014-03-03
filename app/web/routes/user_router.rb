require_relative "./web_router"
require_relative "../../../lib/models"
require_relative "../../../app/api/v1/helpers/with_auth"

module Evercam
  class WebUserRouter < WebRouter

    helpers do
      def auth
        WithAuth.new(env)
      end
    end

    get '/users/:username' do |username|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      begin
        auth.allow? { |r| @user.allow?(AccessRight::VIEW, r) }
        @cameras = Camera.where(:owner_id => @user.id)
      rescue AuthenticationError, AuthorizationError
        @cameras = Camera.where(:owner_id => @user.id, :is_public => true)
      end

      @vendors = Vendor.order(:name)
      @timezones = Timezone::Zone.names
      erb 'users/user_view'.to_sym

    end

    get '/users/:username/profile' do |username|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      auth.allow? { |r| @user.allow?(AccessRight::VIEW, r) }

      @countries = Country.all
      erb 'users/user_profile'.to_sym

    end

    get '/users/:username/cameras/:camera' do |username, camera|
      @user = User.by_login(username)
      raise NotFoundError, 'Username does not exist' unless @user

      auth.allow? { |r| @user.allow?(AccessRight::VIEW, r) }

      @camera = Camera.by_exid(camera)
      raise NotFoundError, 'Camera does not exist' unless @camera

      @vendors = Vendor.order(:name)
      @timezones = Timezone::Zone.names
      erb 'users/cameras/camera_view'.to_sym
    end

    get '/user' do
      user = auth.user
      raise NotFoundError, 'Not logged in' unless user

      content_type :json
      {id:         user.username,
       forename:   user.forename,
       lastname:   user.lastname,
       username:   user.username,
       email:      user.email,
       country:    user.country.iso3166_a2,
       created_at: user.created_at.to_i,
       updated_at: user.updated_at.to_i}.to_json
    end

  end
end
