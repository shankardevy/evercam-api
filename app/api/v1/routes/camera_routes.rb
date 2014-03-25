require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    TIMEOUT = 5

    include WebErrors
    helpers do
      include CameraHelper
    end

    #---------------------------------------------------------------------------
    # GET /cameras/test
    #---------------------------------------------------------------------------
    desc 'Tests if given camera parameters are correct', {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :external_url, type: String, desc: "External camera url."
      requires :jpg_url, type: String, desc: "Snapshot url."
      requires :cam_username, type: String, desc: "Camera username."
      requires :cam_password, type: String, desc: "Camera password."
    end
    get '/cameras/test' do
      auth = "#{params[:cam_username]}:#{params[:cam_password]}"
      begin
        response  = Typhoeus::Request.get(params[:external_url] + params[:jpg_url],
                                          userpwd: auth,
                                          timeout: TIMEOUT,
                                          connecttimeout: TIMEOUT)
      rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
        raise BadRequestError, 'Invalid URL'
      end
      if response.success?
        data = Base64.encode64(response.body).gsub("\n", '')
        { status: 'ok', data: "data:image/jpeg;base64,#{data}"}
      elsif response.code == 401
        raise AuthorizationError, 'Please check camera username and password'
      else
        raise CameraOfflineError, 'Camera offline'
      end
    end

    #---------------------------------------------------------------------------
    # GET /cameras/:id
    #---------------------------------------------------------------------------
    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:id' do
      authreport!('cameras/get')

      camera = nil
      if Camera.is_mac_address?(params[:id])
        camera = camera_for_mac(caller, params[:id])
      else
        camera = Camera.where(exid: params[:id]).first
      end
      raise(Evercam::NotFoundError, "Camera not found") if camera.nil?

      rights = requester_rights_for(camera)
      if !rights.allow?(AccessRight::LIST)
        raise AuthorizationError.new if camera.is_public?
        raise NotFoundError.new if !camera.is_public?
      end

      CameraActivity.create(
        camera: camera,
        access_token: access_token,
        action: 'accessed',
        done_at: Time.now,
        ip: request.ip
      )

      present Array(camera), with: Presenters::Camera, minimal: !rights.allow?(AccessRight::VIEW)
    end

    resource :cameras do
      before do
        authorize!
      end

      #-------------------------------------------------------------------------
      # POST /cameras
      #-------------------------------------------------------------------------
      desc 'Creates a new camera owned by the authenticating user', {
        entity: Evercam::Presenters::Camera
      }
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :name, type: String, desc: "Camera name."
        requires :is_public, type: Boolean, desc: "Is camera public?"
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: Integer, desc: "External camera http port."
        optional :internal_http_port, type: Integer, desc: "Internal camera http port."
        optional :external_rtsp_port, type: Integer, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: Integer, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
      end
      post do
        authreport!('cameras/post')
        raise BadRequestError.new("Requester is not a user.") if caller.nil? || !caller.instance_of?(User)
        parameters = {}.merge(params).merge(username: caller.username)
        outcome    = Actors::CameraCreate.run(parameters)
        raise OutcomeError, outcome unless outcome.success?
        present Array(outcome.result), with: Presenters::Camera
      end

      #-------------------------------------------------------------------------
      # PATCH /cameras/:id
      #-------------------------------------------------------------------------
      desc 'Updates full or partial data for an existing camera', {
        entity: Evercam::Presenters::Camera
      }
      params do
        requires :id, type: String, desc: "Camera Id."
        optional :name, type: String, desc: "Camera name."
        optional :is_public, type: Boolean, desc: "Is camera public?"
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: Integer, desc: "External camera http port."
        optional :internal_http_port, type: String, desc: "Internal camera http port."
        optional :external_rtsp_port, type: Integer, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: Integer, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
      end
      patch '/:id' do
        authreport!('cameras/patch')

        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

        Camera.db.transaction do
          outcome = Actors::CameraUpdate.run(params)
          raise OutcomeError, outcome unless outcome.success?

          CameraActivity.create(
            camera: camera,
            access_token: access_token,
            action: 'edited',
            done_at: Time.now,
            ip: request.ip
          )
        end

        present Array(camera.reload), with: Presenters::Camera
      end


      #-------------------------------------------------------------------------
      # DELETE /cameras/:id
      #-------------------------------------------------------------------------
      desc 'Deletes a camera from Evercam along with any stored media', {
        entity: Evercam::Presenters::Camera
      }
      delete '/:id' do
        authreport!('cameras/delete')

        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

        camera.destroy
        {}
      end


      #-------------------------------------------------------------------------
      # GET /cameras/:id/shares
      #-------------------------------------------------------------------------
      desc 'Get the list of shares for a specified camera', {
        entity: Evercam::Presenters::CameraShare
      }
      params do
        requires :id, type: String, desc: "The unique identifier for a camera."
      end
      get '/:id/shares' do
        authreport!('shares/get')

        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

        shares = CameraShare.where(camera_id: camera.id).to_a
        present shares, with: Presenters::CameraShare
      end

      #-------------------------------------------------------------------------
      # POST /cameras/:id/share
      #-------------------------------------------------------------------------
      desc 'Create a new camera share', {
        entity: Evercam::Presenters::CameraShare
      }
      params do
        requires :email, type: String, desc: "Email address of user to share the camera with."
        requires :rights, type: String, desc: "A comma separate list of the rights to be granted with the share."
        optional :message, String, desc: "Not currently used."
        optional :notify, type: Boolean, desc: "Not currently used."
      end
      post '/:id/share' do
        authreport!('share/post')

        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.is_owner?

        outcome = Actors::ShareCreate.run(params)
        present [outcome.result], with: Presenters::CameraShare
      end

      #-------------------------------------------------------------------------
      # DELETE /cameras/:id/share
      #-------------------------------------------------------------------------
      desc 'Delete an existing camera share', {}
      params do
        requires :id, type: String, desc: "The unique identifier for a camera."
        requires :share_id, type: Integer, desc: "The unique identifier of the share to be deleted."
      end
      delete '/:id/share' do
        authreport!('share/delete')

        camera = ::Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.is_owner?

        Actors::ShareDelete.run(params)
        {}
      end

      #-------------------------------------------------------------------------
      # PATCH /cameras/share/:id
      #-------------------------------------------------------------------------
      desc 'Update an existing camera share (COMING SOON)'
      patch '/share/:id' do
        raise ComingSoonError
      end
    end

  end
end

