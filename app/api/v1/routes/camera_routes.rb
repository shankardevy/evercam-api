require_relative '../presenters/camera_presenter'

module Evercam
  class V1CameraRoutes < Grape::API

    include WebErrors

    helpers do
      def check_rights(right)
        if right != :view
          raise AuthenticationError unless auth.token
        end

        camera = ::Camera.by_exid(params[:id])
        raise NotFoundError, 'Camera was not found' unless camera

        unless camera.allow?(right, auth.token)
          raise AuthenticationError unless auth.token
          raise AuthorizationError, "not authorized to #{right} this camera"
        end
        camera
      end
    end

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
      camera = check_rights(:view)

      present Array(camera), with: Presenters::Camera
    end

    desc 'Updates full or partial data for an existing camera', {
      entity: Evercam::Presenters::Camera
    }
    put '/cameras/:id' do
      check_rights(:edit)
      inputs = params.merge(username: auth.token.grantor.username)

      outcome = Actors::CameraUpdate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?
      camera = outcome.result

      present Array(camera), with: Presenters::Camera
    end

    desc 'Deletes a camera from Evercam along with any stored media', {
      entity: Evercam::Presenters::Camera
    }
    delete '/cameras/:id' do
      camera = check_rights(:edit)
      camera.destroy
      {}
    end

  end
end

