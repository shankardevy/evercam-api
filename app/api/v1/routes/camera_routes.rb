require_relative '../presenters/camera_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    desc 'Creates a new camera owned by the authenticating user', {
      entity: Evercam::Presenters::Camera
    }
    post '/cameras' do
      raise AuthenticationError unless auth.token
      inputs = params.merge(username: auth.token.grantor.username)

      outcome = Actors::CameraCreate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?
      camera = outcome.result

      present Array(camera), with: Presenters::Camera
    end

    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:id' do
      camera = ::Camera.by_exid(params[:id])
      raise NotFoundError, 'Camera was not found' unless camera

      unless camera.allow?(:view, auth.token)
        raise AuthenticationError unless auth.token
        raise AuthorizationError, 'not authorized to view this camera'
      end

      present Array(camera), with: Presenters::Camera
    end

    desc 'Updates full or partial data for an existing camera', {
      entity: Evercam::Presenters::Camera
    }
    put '/cameras/:id' do
      raise AuthenticationError unless auth.token
      inputs = params.merge(username: auth.token.grantor.username)

      camera = ::Camera.by_exid(params[:id])
      raise NotFoundError, 'Camera was not found' unless camera

      unless camera.allow?(:edit, auth.token)
        raise AuthenticationError unless auth.token
        raise AuthorizationError, 'not authorized to edit this camera'
      end

      outcome = Actors::CameraUpdate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?
      camera = outcome.result

      present Array(camera), with: Presenters::Camera
    end

    desc 'Deletes a camera from Evercam along with any stored media'
    delete '/cameras/:id' do
      camera = ::Camera.by_exid(params[:id])
      camera.delete
    end

  end
end

