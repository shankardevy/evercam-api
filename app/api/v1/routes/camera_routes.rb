require_relative '../presenters/camera_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    desc 'Creates a new camera owned by the authenticating user', {
      entity: Evercam::Presenters::Camera
    }
    post '/cameras' do
      auth.demand do |req, usr|
        inputs = params.merge(username: usr.username)

        outcome = Actors::CameraCreate.run(inputs)
        raise OutcomeError, outcome unless outcome.success?
        camera = outcome.result

        present Array(camera), with: Presenters::Camera
      end
    end

    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:id' do
      camera = ::Camera.by_exid(params[:id])
      raise NotFoundError, 'Camera was not found' unless camera

      auth.allow? do |req|
        camera.allow?(:view, req)
      end

      present Array(camera), with: Presenters::Camera
    end

    desc 'Updates full or partial data for an existing camera (COMING SOON)'
    put '/cameras/:id' do

    end

    desc 'Deletes a camera from Evercam along with any stored media (COMING SOON)'
    delete '/cameras/:id' do
    end

  end
end

