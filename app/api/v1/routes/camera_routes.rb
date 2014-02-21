require_relative '../presenters/camera_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    desc 'Creates a new camera owned by the authenticating user', {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      requires :name, type: String, desc: "Camera name."
      requires :endpoints, type: Array, desc: "Endpoints."
      requires :is_public, type: Boolean, desc: "Is camera public?"
      optional :snapshots, type: Hash, desc: "Snapshots."
      optional :auth, type: Hash, desc: "Auth."
    end
    post '/cameras' do
      auth.demand do |req, usr|
        authreport!('cameras/post')
        inputs = params.merge(username: usr.username)

        outcome = Actors::CameraCreate.run(inputs)
        raise OutcomeError, outcome unless outcome.success?

        present Array(outcome.result), with: Presenters::Camera
      end
    end

    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:id' do
      authreport!('cameras/get')
      if Camera.is_mac_address?(params[:id])
        camera = auth.first_allowed(Camera.where(mac_address: params[:id])) do |record, token|
          record.allow?(AccessRight::SNAPSHOT, token)
        end
        raise(Evercam::NotFoundError, "Camera not found") if camera.nil?
      else
        camera = Camera.by_exid!(params[:id])
        auth.allow? { |r| camera.allow?(AccessRight::SNAPSHOT, r) }
      end
      present Array(camera), with: Presenters::Camera
    end

    desc 'Updates full or partial data for an existing camera', {
      entity: Evercam::Presenters::Camera
    }
    params do
      requires :id, type: String, desc: "Camera Id."
      optional :name, type: String, desc: "Camera name."
      optional :endpoints, type: Array, desc: "Endpoints."
      optional :is_public, type: Boolean, desc: "Is camera public?"
      optional :snapshots, type: Hash, desc: "Snapshots."
      optional :auth, type: Hash, desc: "Auth."
    end
    patch '/cameras/:id' do
      authreport!('cameras/patch')
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      outcome = Actors::CameraUpdate.run(params)
      raise OutcomeError, outcome unless outcome.success?

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

  end
end

