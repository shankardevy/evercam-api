require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    desc 'Starts the new user signup process', {
      entity: Evercam::Presenters::User
    }
    params do
      requires :forename, type: String, desc: "Forename."
      requires :lastname, type: String, desc: "Lastname."
      requires :username, type: String, desc: "Username."
      requires :country, type: String, desc: "Country."
      requires :email, type: String, desc: "Email."
    end
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
        s.allow?(:view, auth.token)
      end

      present cameras, with: Presenters::Camera
    end

    desc 'Returns available information for the user (COMING SOON)'
    get '/users/:id' do
      raise ComingSoonError
    end

    desc 'Returns the set of camera and other rights you have granted and have been granted (COMING SOON)'
    get '/users/:id/rights' do
      raise ComingSoonError
    end

    desc 'Updates full or partial data on your existing user account', {
      entity: Evercam::Presenters::User
    }
    put '/users/:id' do
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user
      auth.allow? { |r| user.allow?(:edit, r) }

      outcome = Actors::UserUpdate.run(params)
      raise OutcomeError, outcome unless outcome.success?

      present Array(user.reload), with: Presenters::User
    end

    desc 'Delete your account, any cameras you own and all stored media', {
      entity: Evercam::Presenters::User
    }
    delete '/users/:id' do
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user
      auth.allow? { |r| user.allow?(:edit, r) }
      user.destroy
      {}
    end

  end
end

