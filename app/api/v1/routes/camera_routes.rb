require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    TIMEOUT = 5

    desc 'Creates a new camera owned by the authenticating user', {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      requires :name, type: String, desc: "Camera name."
      requires :is_public, type: Boolean, desc: "Is camera public?"
      optional :external_url, type: String, desc: "External camera url."
      optional :internal_url, type: String, desc: "Internal camera url."
      optional :jpg_url, type: String, desc: "Snapshot url."
      optional :cam_username, type: String, desc: "Camera username."
      optional :cam_password, type: String, desc: "Camera password."
    end
    post '/cameras', :http_codes => [
      [400, "Invalid parameter entry"],
      [401, "Authentication error"],
      [403, "Authorization Error"],
    ]  do
      auth.demand do |req, usr|
        authreport!('cameras/post')
        inputs = params.merge(username: usr.username)

        outcome = Actors::CameraCreate.run(inputs)
        raise OutcomeError, outcome unless outcome.success?

        present Array(outcome.result), with: Presenters::Camera
      end
    end

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

    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:id' do
      authreport!('cameras/get')
      a_token = nil
      strip   = false
      if Camera.is_mac_address?(params[:id])
        camera = auth.first_allowed(Camera.where(mac_address: params[:id])) do |record, token|
          a_token = token
          rights  = AccessRightSet.for(record, (token.nil? ? nil : token.target))
          allowed = (rights.allow?(AccessRight::VIEW) || rights.is_resource_public?)
          strip   = (allowed && !rights.is_owner?)
          allowed
        end
        raise(Evercam::NotFoundError, "Camera not found") if camera.nil?
      else
        camera = Camera.by_exid!(params[:id])
        auth.allow? do |token|
          a_token = token
          rights  = AccessRightSet.for(camera, (token.nil? ? nil : token.target))
          allowed = (rights.allow?(AccessRight::VIEW) || rights.is_resource_public?)
          strip   = (allowed && !rights.is_owner?)
          allowed
        end
      end

      CameraActivity.create(
        camera: camera,
        access_token: a_token,
        action: 'accessed',
        done_at: Time.now,
        ip: request.ip
      )

      present Array(camera), with: Presenters::Camera, minimal: strip
    end

    desc 'Updates full or partial data for an existing camera', {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      optional :name, type: String, desc: "Camera name."
      optional :is_public, type: Boolean, desc: "Is camera public?"
      optional :external_url, type: String, desc: "External camera url."
      optional :internal_url, type: String, desc: "Internal camera url."
      optional :jpg_url, type: String, desc: "Snapshot url."
      optional :cam_username, type: String, desc: "Camera username."
      optional :cam_password, type: String, desc: "Camera password."
    end
    patch '/cameras/:id' do
      authreport!('cameras/patch')
      camera = ::Camera.by_exid!(params[:id])
      a_token = nil
      auth.allow? do |token|
        a_token = token
        camera.allow?(:edit, token)
      end

      Camera.db.transaction do
        outcome = Actors::CameraUpdate.run(params)
        raise OutcomeError, outcome unless outcome.success?

        CameraActivity.create(
          camera: camera,
          access_token: a_token,
          action: 'edited',
          done_at: Time.now,
          ip: request.ip
        )
      end

      present Array(camera.reload), with: Presenters::Camera
    end

    desc 'Deletes a camera from Evercam along with any stored media', {
      entity: Evercam::Presenters::Camera
    }
    delete '/cameras/:id' do
      authreport!('cameras/delete')
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }
      camera.destroy
      {}
    end

    desc 'Get the list of shares for a specified camera', {
      entity: Evercam::Presenters::CameraShare
    }
    params do
      requires :id, type: String, desc: "The unique identifier for a camera."
    end
    get '/cameras/:id/shares' do
      authreport!('shares/get')
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? {|token| camera.allow?(AccessRight::VIEW, token)}

      shares = CameraShare.where(camera_id: camera.id).to_a
      present shares, with: Presenters::CameraShare
    end

    desc 'Create a new camera share', {
      entity: Evercam::Presenters::CameraShare
    }
    params do
      requires :email, type: String, desc: "Email address of user to share the camera with."
      requires :rights, type: String, desc: "A comma separate list of the rights to be granted with the share."
      optional :message, String, desc: "Not currently used."
      optional :notify, type: Boolean, desc: "Not currently used."
    end
    post '/cameras/:id/share' do
      authreport!('share/post')
      camera = ::Camera.by_exid!(params[:id])

      auth.allow? {|token, user| camera.owner_id == (user ? user.id : nil)}

      outcome = Actors::ShareCreate.run(params)
      present [outcome.result], with: Presenters::CameraShare
    end

    desc 'Delete an existing camera share', {}
    params do
      requires :id, type: String, desc: "The unique identifier for a camera."
      requires :share_id, type: Integer, desc: "The unique identifier of the share to be deleted."
    end
    delete '/cameras/:id/share' do
      authreport!('share/delete')
      camera = ::Camera.by_exid!(params[:id])

      auth.allow? {|token, user| camera.owner_id == (user ? user.id : nil)}

      Actors::ShareDelete.run(params)
      {}
    end

    desc 'Update an existing camera share (COMING SOON)'
    patch '/cameras/share/:id' do
      raise ComingSoonError
    end

  end
end

