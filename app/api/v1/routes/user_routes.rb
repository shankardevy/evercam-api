require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    namespace :testusername do
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
        #-----------------------------------------------------------------------
        # GET /v1/users/:id/cameras
        #-----------------------------------------------------------------------
        desc 'Returns the set of cameras associated with a user', {
          entity: Evercam::Presenters::Camera
        }
        params do
          requires :id, type: String, desc: "The user name or email address of the user."
          optional :include_shared, type: Boolean, desc: "Set to true to include cameras shared with the user in the fetch."
        end
        get :cameras do
          authreport!('users/cameras/get')
          user = ::User.by_login(params[:id])
          raise NotFoundError, 'user does not exist' unless user

          query = Camera.where(owner: user)
          if params[:include_shared]
            query = query.association_left_join(:shares).or(Sequel.qualify(:shares,
                                                                           :user_id) => user.id)
            query = query.group(Sequel.qualify(:cameras, :id))
            query = query.select(Sequel.qualify(:cameras, :id),
                                 Sequel.qualify(:cameras, :created_at),
                                 Sequel.qualify(:cameras, :updated_at),
                                 :exid,
                                 :owner_id, :is_public, :config,
                                 :name, :last_polled_at, :is_online,
                                 :timezone, :last_online_at, :location,
                                 :mac_address, :model_id, :discoverable)
          end

          cameras = []
          query.order(:name).all.select do |camera|
            rights = requester_rights_for(camera)
            if rights.allow_any?(AccessRight::LIST, AccessRight::VIEW)
              presenter = Evercam::Presenters::Camera.new(camera)
              cameras << presenter.as_json(minimal: !rights.allow?(AccessRight::VIEW), user: user)
            end
          end

          {cameras: cameras}
        end
      end

      #-------------------------------------------------------------------------
      # POST /v1/users
      #-------------------------------------------------------------------------
      desc 'Starts the new user signup process', {
        entity: Evercam::Presenters::User
      }
      params do
        requires :forename, type: String, desc: "Forename."
        requires :lastname, type: String, desc: "Lastname."
        requires :username, type: String, desc: "Username."
        requires :country, type: String, desc: "Country."
        requires :email, type: String, desc: "Email."
        requires :password, type: String, desc: "Password."
        optional :share_request_key, type: String, desc: "The key for a camera share request to be processed during the sign up."
      end
      post do
        authreport!('users/post')
        params[:country].downcase!
        outcome = Actors::UserSignup.run(params)
        raise OutcomeError, outcome unless outcome.success?

        user = outcome.result
        if params[:share_request_key]
          outcome = Actors::ShareCreateForRequest.run({key: params[:share_request_key],
                                                       email: params[:email]})
          if !outcome.success?
            Rails.logger.error "Failed to create camera share for camera share "\
                               "request key '#{params[:share_request_key]}'."
          end
        end

        present Array(user), with: Presenters::User
      end
    end

    resource :users do
      before do
        authorize!
      end

      route_param :id do
        #-----------------------------------------------------------------------
        # GET /v1/users/rights
        #-----------------------------------------------------------------------
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

      #-------------------------------------------------------------------------
      # GET /v1/users/:id
      #-------------------------------------------------------------------------
      desc 'Returns available information for the user'
      get '/:id' do
        authreport!('users/get')
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        present Array(target), with: Presenters::User
      end

      #-------------------------------------------------------------------------
      # PATCH /v1/users/:id
      #-------------------------------------------------------------------------
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
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::UserUpdate.run(params)
        raise OutcomeError, outcome unless outcome.success?

        present Array(target.reload), with: Presenters::User
      end

      #-------------------------------------------------------------------------
      # DELETE /v1/users/:id
      #-------------------------------------------------------------------------
      desc 'Delete your account, any cameras you own and all stored media', {
        entity: Evercam::Presenters::User
      }
      delete '/:id' do
        authreport!('users/delete')
        target = ::User.by_login(params[:id])
        raise NotFoundError, 'user does not exist' unless target

        rights = requester_rights_for(target, AccessRight::USER)
        raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

        target.destroy
        {}
      end

      #-------------------------------------------------------------------------
      # GET /v1/users/:id/credentials
      #-------------------------------------------------------------------------
      desc "Fetch API credentials for an authenticated user."
      params do
        requires :id, type: String, desc: "User name for the user to fetch credentials for."
        requires :password, type: String, desc: "Password for the user to fetch credentials for."
      end
      get '/:id/credentials' do
        authreport!('users/credentials')
        user = User.by_login(params[:id])
        raise NotFoundError.new("No user with an id of #{params[:id]} exists.") if user.nil?

        if user.password != params[:password]
          raise AuthenticationError.new("Invalid user name and/or password.")
        end

        {api_id: user.api_id, api_key: user.api_key}
      end
    end
  end
end

