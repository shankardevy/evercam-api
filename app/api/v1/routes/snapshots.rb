module Evercam
  class APIv1

    get '/streams/:name/snapshots' do
      stream = ::Stream.by_name(params[:name])
      raise NotFoundError, 'stream was not found' unless stream

      unless stream.is_public? || auth.has_right?('stream:view', stream)
        raise AuthorizationError, 'not authorized to view this stream'
      end

      device = stream.device

      {
        uris: {
          external: device.external_uri,
          internal: device.internal_uri
        },
        formats: {
          jpg: {
            path: stream.snapshot_path
          }
        },
        auth: {
          basic: {
            username: device.username,
            password: device.password
          }
        }
      }
    end

  end
end

