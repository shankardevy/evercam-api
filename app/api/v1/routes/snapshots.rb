module Evercam
  class APIv1

    get '/streams/:name/snapshots' do
      stream = ::Stream.by_name(params[:name])
      raise NotFoundError, 'stream was not found' unless stream

      unless stream.is_public? || auth.has_right?('view', stream)
        raise ForbiddenError, 'not authorized to access this stream'
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

