require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    desc 'Starts the new user signup process', {
      entity: Evercam::Presenters::User
    }
    post '/users' do
      outcome = Actors::UserSignup.run(params)
      raise OutcomeError, outcome unless outcome.success?

      user = outcome.result
      present Array(user), with: Presenters::User
    end

    desc 'Returns the set of cameras owned by a particular user', {
      entity: Evercam::Presenters::Camera
    }
    get '/users/:id/cameras' do
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user

      cameras = user.cameras.select do |s|
        s.is_public || (auth.user && s.has_right?('view', auth.user))
      end

      present cameras, with: Presenters::Camera
    end

  end
end

