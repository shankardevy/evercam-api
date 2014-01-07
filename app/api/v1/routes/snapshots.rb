module Evercam
  class APIv1

    get '/streams/:name/snapshots/new' do
      stream = ::Stream.by_name(params[:name])
      raise NotFoundError, 'stream was not found' unless stream

      unless stream.is_public? || auth.has_right?('view', stream)
        raise AuthorizationError, 'not authorized to view this stream'
      end

      {
        uris: {
          external: stream.config['endpoints'][0],
          internal: stream.config['endpoints'][0],
        },
        formats: {
          jpg: {
            path: stream.config['snapshots']['jpg']
          }
        },
        auth: stream.config['auth']
      }
    end

  end
end

