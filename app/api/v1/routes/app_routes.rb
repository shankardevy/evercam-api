module Evercam
  class V1AppRoutes < Grape::API

    #---------------------------------------------------------------------------
    # GET /v1/cameras/:id/apps
    #---------------------------------------------------------------------------
    desc 'Returns information about enabled apps for a given camera', {
      entity: Evercam::Presenters::App
    }
    params do
      requires :id, type: String, desc: "Camera Id."
    end
    get '/cameras/:id/apps' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      apps = App.where(camera_id: camera.id).first
      apps = App.create(camera_id: camera.id) if apps.blank?

      present Array(apps), with: Presenters::App
    end

    #---------------------------------------------------------------------------
    # PATCH /v1/cameras/:id/apps
    #---------------------------------------------------------------------------
    desc 'Returns information about enabled apps for a given camera', {
      entity: Evercam::Presenters::App
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      optional :local_recording, type: 'Boolean', desc: "True if the app is enabled, false otherwise"
      optional :cloud_recording, type: 'Boolean', desc: "True if the app is enabled, false otherwise"
      optional :motion_detection, type: 'Boolean', desc: "True if the app is enabled, false otherwise"
      optional :watermark, type: 'Boolean', desc: "True if the app is enabled, false otherwise"
    end
    patch '/cameras/:id/apps' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

      outcome = Actors::AppUpdate.run(params)
      unless outcome.success?
        raise OutcomeError, outcome.to_json
      end
      present Array(outcome.result), with: Presenters::App
    end
  end
end
