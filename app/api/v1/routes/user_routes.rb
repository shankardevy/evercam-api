require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    namespace :testusername do
      helpers do
        include AuthorizationHelper
        include LoggingHelper
        include SessionHelper
      end

      before do
        authorize!
      end

      desc 'Internal endpoint only, keep hidden', {
        :hidden => true
      }
      params do
        requires :username, type: String
      end
      get do
        user = ::User.by_login(params[:username])
        raise BadRequestError, 'Username already in use' if user

        {:message => 'OK'}
      end
    end

    resource :users do
      route_param :id do
        desc 'Returns the set of cameras owned by a particular user', {
          entity: Evercam::Presenters::Camera
        }
        get :cameras do
          authreport!('users/cameras/get')
          user = ::User.by_login(params[:id])
          raise NotFoundError, 'user does not exist' unless user

          cameras = user.cameras.select do |s|
            s.allow?(AccessRight::SNAPSHOT, auth.access_token)
          end

          present cameras, with: Presenters::Camera
        end
      end
    end

    resource :users do
      helpers do
        include AuthorizationHelper
        include LoggingHelper
        include SessionHelper
      end

      before do
        authorize!
      end

      route_param :id do
        desc 'Returns the set of camera and other rights you have granted and have been granted (COMING SOON)'
        get :rights do
          raise ComingSoonError
        end
      end
    end

    resource :users do
      helpers do
        include AuthorizationHelper
        include LoggingHelper
        include SessionHelper
      end

      before do
        authorize!
      end

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
      post do
        authreport!('users/post')
        params[:country].downcase!
        outcome = Actors::UserSignup.run(params)
        raise OutcomeError, outcome unless outcome.success?

        user = outcome.result
        present Array(user), with: Presenters::User
      end

      desc 'Returns available information for the user'
      get '/:id' do
        authreport!('users/get')
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        # NOTE: This is not a valid rights check for this request so I've commented
        # it out but will need to be replaced with one that is. PW 18/03/14
        # auth.allow? { |r| user.allow?(AccessRight::SNAPSHOT, r) }
        auth.allow? {|token, user| !user.nil? && user.id == target.id}

        present Array(target), with: Presenters::User
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
      patch '/:id' do
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
      delete '/:id' do
        authreport!('users/delete')
        user = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless user
        auth.allow? { |r| user.allow?(:edit, r) }
        user.destroy
        {}
      end
    end
  end
end

