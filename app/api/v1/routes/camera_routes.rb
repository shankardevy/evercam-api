require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'
require "typhoeus/adapters/faraday"

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
    desc 'Tests if given camera parameters are correct'
    params do
      requires :external_url, type: String, desc: "External camera url."
      requires :jpg_url, type: String, desc: "Snapshot url."
      optional :cam_username, type: String, desc: "Camera username."
      optional :cam_password, type: String, desc: "Camera password."
    end
    get '/cameras/test' do
      begin
        conn = Faraday.new(:url => params[:external_url]) do |faraday|
          faraday.request :basic_auth, params[:cam_username], params[:cam_password]
          faraday.adapter  :typhoeus
          faraday.options.timeout = 5           # open/read timeout in seconds
          faraday.options.open_timeout = 5      # connection open timeout in seconds
        end
        response  = conn.get do |req|
          req.url params[:jpg_url].gsub('X_QQ_X', '?').gsub('X_AA_X', '&')
        end
      rescue URI::InvalidURIError => error
        raise BadRequestError, "Invalid URL. Cause: #{error}"
      rescue Faraday::TimeoutError
        raise CameraOfflineError, 'Camera offline'
      end
      if response.success?
        data = Base64.encode64(response.body).gsub("\n", '')
        { status: 'ok', data: "data:#{response.headers.fetch('content-type', 'image/jpg')};base64,#{data}"}
      elsif response.status == 401
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
    params do
      requires :id, type: String, desc: "Camera Id."
      optional :thumbnail, type: 'Boolean', desc: "Set to true to get base64 encoded 150x150 thumbnail with camera view or null if it's not available."
    end
    get '/cameras/:id' do
      authreport!('cameras/get')

      if Camera.is_mac_address?(params[:id])
        camera = camera_for_mac(caller, params[:id])
      else
        camera = Camera.where(exid: params[:id]).first
      end
      raise(Evercam::NotFoundError, "Camera not found for camera id '#{params[:id]}'.") if camera.nil?

      rights = requester_rights_for(camera)
      unless rights.allow?(AccessRight::LIST)
        raise AuthorizationError.new if camera.is_public?
        raise NotFoundError.new unless camera.is_public?
      end

      CameraActivity.create(
        camera: camera,
        access_token: access_token,
        action: 'accessed',
        done_at: Time.now,
        ip: request.ip
      )

      options = {minimal: !rights.allow?(AccessRight::VIEW),
                 with: Presenters::Camera,
                 thumbnail: params[:thumbnail]}
      options[:user] = rights.requester unless rights.requester.nil?
      present([camera], options)
    end

    #---------------------------------------------------------------------------
    # GET /cameras
    #---------------------------------------------------------------------------
    desc "Returns data for a specified set of cameras. The ultimate intention "\
         "would be to expand this functionality to be a more general search. "\
         "The current implementation is as a basic absolute match list capability.", {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :ids, type: String, desc: "Comma separated list of camera identifiers for the cameras being queried."
      optional :api_id, type: String, desc: "Caller API id used to authenticate the request."
      optional :api_key, type: String, desc: "Caller API key used to authenticate the request."
    end
    get '/cameras' do
      authreport!('cameras/get')

      cameras = []
      if params.include?(:ids) && params[:ids]
        ids = params[:ids].split(",").inject([]) {|list, entry| list << entry.strip}
        Camera.where(exid: ids).each do |camera|
          rights = requester_rights_for(camera)
          if rights.allow_any?(AccessRight::LIST, AccessRight::VIEW)
            presenter = Evercam::Presenters::Camera.new(camera)
            cameras << presenter.as_json(minimal: !rights.allow?(AccessRight::VIEW))
          end
        end
      end
      {cameras: cameras}
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
        requires :is_public, type: 'Boolean', desc: "Is camera public?"
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: String, desc: "External camera http port."
        optional :internal_http_port, type: String, desc: "Internal camera http port."
        optional :external_rtsp_port, type: String, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: String, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
        optional :location_lng, type: Float, desc: "Camera GPS longitude location."
        optional :location_lat, type: Float, desc: "Camera GPS latitude location."
      end
      post do
        authreport!('cameras/post')
        raise BadRequestError.new("Requester is not a user.") if caller.nil? || !caller.instance_of?(User)
        parameters = {}.merge(params).merge(username: caller.username)
        outcome    = Actors::CameraCreate.run(parameters)
        unless outcome.success?
          IntercomEventsWorker.perform_async('failed-creating-camera', caller.email)
          raise OutcomeError, outcome
        end
        IntercomEventsWorker.perform_async('created-camera', caller.email)
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
        optional :is_public, type: 'Boolean', desc: "Is camera public?"
        optional :external_host, type: String, desc: "External camera host."
        optional :internal_host, type: String, desc: "Internal camera host."
        optional :external_http_port, type: String, desc: "External camera http port."
        optional :internal_http_port, type: String, desc: "Internal camera http port."
        optional :external_rtsp_port, type: String, desc: "External camera rtsp port."
        optional :internal_rtsp_port, type: String, desc: "Internal camera rtsp port."
        optional :jpg_url, type: String, desc: "Snapshot url."
        optional :cam_username, type: String, desc: "Camera username."
        optional :cam_password, type: String, desc: "Camera password."
        optional :location_lng, type: Float, desc: "Camera GPS longitude location."
        optional :location_lat, type: Float, desc: "Camera GPS latitude location."
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
        if params[:is_public] and not caller.kind_of?(Client)
          IntercomEventsWorker.perform_async('made-camera-public', caller.email)
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
      # PUT /cameras/:id
      #-------------------------------------------------------------------------
      desc 'Transfers the ownership of a camera from one user to another', {
        entity: Evercam::Presenters::Camera
      }
      params do
         requires :id, type: String, desc: "The unique identifier for the camera."
         requires :user_id, type: String, desc: "The Evercam user name or email address for the new camera owner."
      end
      put '/:id' do
        authreport!('cameras/transfer')

        camera = Camera.by_exid!(params[:id])
        rights = requester_rights_for(camera)
        raise AuthorizationError.new if !rights.is_owner?

        new_owner = User.by_login(params[:user_id])
        raise NotFoundError.new("Specified user does not exist.") if new_owner.nil?

        camera.update(owner: new_owner)
        present Array(camera), with: Presenters::Camera
      end
    end
  end
end

