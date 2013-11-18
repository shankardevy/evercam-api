module Evercam
  class APIv1

    get '/streams/:name/snapshots' do
      stream = ::Stream.by_name(params[:name])

      error! 'requested stream was not found', 404 unless stream
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
