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

      cloud_recording = CloudRecording.where(camera_id: camera.id).first.present?

      apps = OpenStruct.new
      apps.local_recording = false
      apps.cloud_recording = cloud_recording
      apps.motion_detection = false
      apps.watermark = false

      present Array(apps), with: Presenters::App
    end
  end
end
