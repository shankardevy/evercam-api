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
      authreport!('users/post')
      outcome = Actors::UserSignup.run(params)
      raise OutcomeError, outcome unless outcome.success?

      user = outcome.result
      present Array(user), with: Presenters::User
    end

    desc 'Returns the set of cameras owned by a particular user', {
      entity: Evercam::Presenters::Camera
    }
    get '/users/:id/cameras' do
      authreport!('users/cameras/get')
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user

      cameras = user.cameras.select do |s|
        s.allow?(AccessRight::SNAPSHOT, auth.access_token)
      end

      present cameras, with: Presenters::Camera
    end

    desc 'Returns available information for the user'
    get '/users/:id' do
      authreport!('users/get')
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user
      auth.allow? { |r| user.allow?(AccessRight::SNAPSHOT, r) }

      present Array(user), with: Presenters::User
    end

    desc 'Returns the set of camera and other rights you have granted and have been granted (COMING SOON)'
    get '/users/:id/rights' do
      raise ComingSoonError
    end

    desc 'Updates full or partial data on your existing user account', {
      entity: Evercam::Presenters::User
    }
    params do
      requires :id, type: String, desc: "Username."
      optional :forename, type: String, desc: "Forename."
      optional :lastname, type: String, desc: "Lastname."
      optional :username, type: String, desc: "Username."
      optional :country, type: String, desc: "Country."
      optional :email, type: String, desc: "Email."
    end
    patch '/users/:id' do
      authreport!('users/patch')
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
      authreport!('users/delete')
      user = ::User.by_login(params[:id])
      raise NotFoundError, 'user does not exist' unless user
      auth.allow? { |r| user.allow?(:edit, r) }
      user.destroy
      {}
    end

  end
end

