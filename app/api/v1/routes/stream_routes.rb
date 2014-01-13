require_relative '../presenters/camera_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    desc 'Returns all data for a given camera', {
      entity: Evercam::Presenters::Camera
    }
    get '/cameras/:name' do
      camera = ::Stream.by_name(params[:name])
      raise NotFoundError, 'camera was not found' unless camera

      unless camera.is_public? || auth.has_right?('view', camera)
        raise AuthorizationError, 'not authorized to view this camera'
      end

      present Array(camera), with: Presenters::Camera
    end

    desc 'Creates a new camera owned by the authenticating user', {
      entity: Evercam::Presenters::Camera
    }
    post '/cameras' do
      inputs = params.merge(username: auth.user!.username)

      outcome = Actors::StreamCreate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?
      camera = outcome.result

      present Array(camera), with: Presenters::Camera
    end

  end
end

