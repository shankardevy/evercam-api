module Evercam
  class V1CloudRecordingRoutes < Grape::API

    #---------------------------------------------------------------------------
    # GET /v1/cameras/:id/apps/cloud_recording
    #---------------------------------------------------------------------------
    desc '', {
      entity: Evercam::Presenters::CloudRecording
    }
    params do
      requires :id, type: String, desc: "Camera Id."
    end
    get '/cameras/:id/apps/cloud-recording' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      cloud_recording = CloudRecording.where(camera_id: camera.id).first

      present Array(cloud_recording), with: Presenters::CloudRecording
    end

    #---------------------------------------------------------------------------
    # POST /v1/cameras/:id/apps/cloud_recording
    #---------------------------------------------------------------------------
    desc '', {
      entity: Evercam::Presenters::CloudRecording
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      requires :frequency, type: Integer, desc: "Frequency of Snapshots per minute"
      requires :storage_duration, type: Integer, desc: "Storage Duration"
      requires :schedule, type: String, desc: "Schedule"
    end
    post '/cameras/:id/apps/cloud-recording' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      outcome = Actors::CloudRecordingCreate.run(params)
      unless outcome.success?
        raise OutcomeError, outcome.to_json
      end
      present Array(outcome.result), with: Presenters::CloudRecording
    end

    #---------------------------------------------------------------------------
    # PATCH /v1/cameras/:id/apps/cloud_recording
    #---------------------------------------------------------------------------
    desc '', {
      entity: Evercam::Presenters::CloudRecording
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      optional :frequency, type: Integer, desc: "Frequency of Snapshots per minute"
      optional :storage_duration, type: Integer, desc: "Storage Duration"
      optional :schedule, type: String, desc: "Schedule"
    end
    patch '/cameras/:id/apps/cloud-recording' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      outcome = Actors::CloudRecordingUpdate.run(params)
      unless outcome.success?
        raise OutcomeError, outcome.to_json
      end
      present Array(outcome.result), with: Presenters::CloudRecording
    end

    #---------------------------------------------------------------------------
    # DELETE /v1/cameras/:id/apps/cloud_recording
    #---------------------------------------------------------------------------
    desc '', {
      entity: Evercam::Presenters::CloudRecording
    }
    params do
      requires :id, type: String, desc: "Camera Id."
    end
    delete '/cameras/:id/apps/cloud-recording' do
      camera = get_cam(params[:id])
      rights = requester_rights_for(camera)
      raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

      cloud_recording = CloudRecording.where(camera_id: camera.id).first
      cloud_recording.delete

      {}
    end
  end
end
