require_relative '../../../../lib/workers'
require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
  class V1ShareRoutes < Grape::API
    include WebErrors

    resource :cameras do
      before do
        authorize!
      end

      #----------------------------------------------------------------------
      # GET /v1/cameras/:id/shares
      #----------------------------------------------------------------------
      desc 'Get the list of shares for a specified camera', {
          entity: Evercam::Presenters::CameraShare
        }
      params do
        requires :id, type: String, desc: 'The unique identifier for the camera.'
        optional :user_id, type: String, desc: 'The unique identifier for the user the camera is shared with.'
      end
      get '/:id/shares' do
        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        shares = []

        if params[:user_id] and !params[:user_id].blank?
          user = User.by_login(params[:user_id])
          raise NotFoundError.new("User does not exist.") if user.blank?

          requester = caller
          if !rights.allow?(AccessRight::LIST) and
            (requester.email != params[:user_id] and
              requester.username != params[:user_id])
            raise AuthorizationError.new
          end

          shares = CameraShare.where(camera_id: camera.id, user_id: user.id).to_a
        else
          if rights.allow?(AccessRight::VIEW)
            shares = CameraShare.eager(:camera, :user, :sharer).where(camera_id: camera.id).all.to_a
          end
        end
        present shares, with: Presenters::CameraShare
      end

      #-------------------------------------------------------------------
      # POST /v1/cameras/:id/shares
      #-------------------------------------------------------------------
      desc 'Create a new camera share', {
          entity: Evercam::Presenters::CameraShare
        }
      params do
        requires :id, type: String, desc: "The unique identifier for a camera."
        requires :email, type: String, desc: "Email address or user name of the user to share the camera with."
        requires :rights, type: String, desc: "A comma separate list of the rights to be granted with the share."
        optional :message, String, desc: "Not currently used."
        optional :notify, type: 'Boolean', desc: "Not currently used."
        optional :grantor, type: String, desc: "The user name of the user who is creating the share."
      end
      post '/:id/shares' do
        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        if !rights.is_owner? && !rights.allow?(AccessRight::EDIT) &&
          # Quick hack to allow following public cameras
          !(camera.is_public && params[:rights] == 'list,snapshot')
          raise AuthorizationError.new
        end
        target_user = User.by_login(params[:email])
        if target_user == camera.owner
          if caller == camera.owner
            raise BadRequestError.new("You can't share with yourself",
                "cant_share_with_yourself",
                params[:email])
          else
            raise BadRequestError.new("User #{camera.owner.username} is the camera owner - you cannot remove their rights",
                params[:email])
          end
        end

        outcome = Actors::ShareCreate.run(params)
        unless outcome.success?
          raise_error(400, "invalid_parameters",
            "Invalid parameters specified to request.",
            *(outcome.errors.keys))
        end

        CameraActivity.create(
          camera: camera,
          access_token: caller.token,
          action: 'shared',
          done_at: Time.now,
          ip: request.ip,
          extra: {:with => params[:email]}
        )

        IntercomEventsWorker.perform_async('shared-camera', caller.email)
        if outcome.result.class == CameraShare
          # Send email to user
          EmailWorker.perform_async({type: 'share', user: caller.username, email: target_user.email, message: params['message'], camera: camera.exid}) unless caller.email == params[:email]
          # Invalidate cache
          key = "camera-rights|#{camera.exid}|#{target_user.username}"
          CacheInvalidationWorker.perform_async(camera.exid)
          Evercam::Services::dalli_cache.delete(key)
          present [outcome.result], with: Presenters::CameraShare
        else
          # Send email to email
          EmailWorker.perform_async({type: 'share_request', user: caller.username, email: params[:email], message: params['message'], camera: camera.exid, key: outcome.result.key}) unless caller.email == params[:email]
          present [outcome.result], with: Presenters::CameraShareRequest
        end
      end

      #-------------------------------------------------------------------
      # DELETE /v1/cameras/:id/shares
      #-------------------------------------------------------------------
      desc 'Delete an existing camera share', {}
      params do
        requires :id, type: String, desc: "The unique identifier for a camera."
        requires :email, type: String, desc: "The email address of user the camera was shared with."
      end
      delete '/:id/shares' do
        camera = Camera.by_exid!(params[:id])
        user = User.by_login(params[:email])
        raise NotFoundError.new if user.nil?
        share = CameraShare.where(camera_id: camera.id, user_id: user.id).first
        raise NotFoundError.new if share.nil?

        rights = requester_rights_for(camera)
        if !rights.allow?(AccessRight::EDIT) && caller.email != user.email
          raise AuthorizationError.new
        end

        outcome = Actors::ShareDelete.run(params.merge!({id: camera.id, user_id: user.id, ip: request.ip}))

        unless outcome.success?
          raise_error(400, "invalid_parameters",
            "Invalid parameters specified for request.",
            *(outcome.errors.keys))
        end

        # Invalidate cache
        key = "camera-rights|#{camera.exid}|#{share.user.username}"
        Evercam::Services::dalli_cache.delete(key)
        invalidate_for_user(share.user.username)

        {}
      end

      #-------------------------------------------------------------------
      # PATCH /v1/cameras/:id/shares
      #-------------------------------------------------------------------
      desc 'Update an existing camera share.', {}
      params do
        requires :id, type: String, desc: "The unique identifier of the camera share to be updated."
        requires :email, type: String, desc: "The email address of user the camera was shared with."
        requires :rights, type: String, desc: "A comma separate list of the rights to be set on the share."
      end
      patch '/:id/shares' do
        camera = Camera.by_exid!(params[:id])
        user = User.by_login(params[:email])
        raise NotFoundError.new if user.nil?
        share = CameraShare.where(camera_id: camera.id, user_id: user.id).first
        raise NotFoundError.new if share.nil?

        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        outcome = Actors::ShareUpdate.run(params.merge!({id: camera.id, user_id: user.id, ip: request.ip}))
        if !outcome.success?
          raise_error(400, "invalid_parameters",
            "Invalid parameters specified for request.",
            *(outcome.errors.keys))
        end

        # Invalidate cache
        key = "camera-rights|#{camera.exid}|#{user.username}"
        Evercam::Services::dalli_cache.delete(key)
        CacheInvalidationWorker.perform_async(camera.exid)

        present [outcome.result], with: Presenters::CameraShare
      end

      #-------------------------------------------------------------------
      # GET /v1/cameras/:id/shares/requests
      #-------------------------------------------------------------------
      desc 'Fetch the list of share requests currently outstanding for a given camera.', {
          entity: Evercam::Presenters::CameraShareRequest
        }
      params do
        requires :id, type: String, desc: "The unique identifier of the camera to fetch share requests for."
        optional :status, type: String, desc: "The request status to fetch, either 'PENDING', 'USED' or 'CANCELLED'."
      end
      get '/:id/shares/requests' do
        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        list = []
        if rights.allow?(AccessRight::VIEW)
          query = CameraShareRequest.where(camera_id: camera.id)
          if params[:status]
            case params[:status].downcase
              when 'used'
                query = query.where(status: CameraShareRequest::USED)
              when 'cancelled'
                query = query.where(status: CameraShareRequest::CANCELLED)
              else
                query = query.where(status: CameraShareRequest::PENDING)
            end
          end
          list = query.to_a
        end
        present list, with: Presenters::CameraShareRequest
      end

      #-------------------------------------------------------------------
      # DELETE /v1/cameras/:id/shares/requests
      #-------------------------------------------------------------------
      desc 'Cancels a pending camera share request for a given camera', {
          entity: Evercam::Presenters::CameraShareRequest
        }
      params do
        requires :id, type: String, desc: "The unique identifier of the camera to fetch share requests for."
        requires :email, type: String, desc: "The email address of user the camera was shared with."
      end
      delete '/:id/shares/requests' do

        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        share_request = CameraShareRequest.where(status: CameraShareRequest::PENDING,
          email: params[:email],
          camera: camera).first
        raise NotFoundError.new if share_request.nil?

        share_request.update(status: CameraShareRequest::CANCELLED)
        {}
      end

      #-------------------------------------------------------------------
      # PATCH /v1/cameras/:id/shares/requests
      #-------------------------------------------------------------------
      desc 'Updates a pending camera share request.', {
          entity: Evercam::Presenters::CameraShareRequest
        }
      params do
        requires :id, type: String, desc: "The unique identifier of the camera share request to update."
        requires :rights, type: String, desc: "The new set of rights to be granted for the share."
        requires :email, type: String, desc: "The email address of user the camera was shared with."
      end
      patch '/:id/shares/requests' do
        camera = Camera.by_exid!(params[:id])

        share_request = CameraShareRequest.where(status: CameraShareRequest::PENDING,
          email: params[:email],
          camera: camera).first
        raise NotFoundError.new if share_request.nil?

        rights = requester_rights_for(camera)
        if !(rights.is_public? && share_request.camera.discoverable?) && !rights.is_owner?
          raise AuthorizationError.new
        end

        params[:rights].split(",").each do |right|
          raise BadRequestError.new if !rights.valid_right?(right.strip.downcase)
        end

        share_request.update(rights: params[:rights])
        present [share_request], with: Presenters::CameraShareRequest
      end
    end

    #-------------------------------------------------------------------
    # GET /v1/users/shares/:id
    #-------------------------------------------------------------------
    desc 'Returns the list of shares currently granted to a user.', {
        entity: Evercam::Presenters::CameraShare,
        hidden: true
      }
    params do
      requires :id, type: String, desc: "The unique identifier of the user to fetch the list of shares for."
      optional :api_id, type: String, desc: "The Evercam API id for the requester."
      optional :api_key, type: String, desc: "The Evercam API key for the requester."
    end
    get '/users/shares/:id' do
      authorize!
      user = User.by_login(params[:id])
      raise NotFoundError.new if user.nil?
      rights = requester_rights_for(user, AccessRight::CAMERAS)
      raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

      shares = CameraShare.where(user_id: user.id)
      present shares.to_a, with: Presenters::CameraShare
    end
  end
end
