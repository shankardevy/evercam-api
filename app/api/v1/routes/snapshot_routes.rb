module Evercam
  class V1SnapshotRoutes < Grape::API

    include WebErrors

    TIMEOUT = 5

    desc 'Returns the list of all snapshots currently stored for this camera (COMING SOON)'
    get '/cameras/:id/snapshots' do
      raise ComingSoonError
    end

    desc 'Returns the snapshot stored for this camera closest to the given timestamp (COMING SOON)'
    get '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

    desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
    post '/cameras/:id/snapshots' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      instant = Time.now
      success = false
      camera.endpoints.each do |endpoint|
        next unless (endpoint.public? rescue false)
        con = Net::HTTP.new(endpoint.host, endpoint.port)

        begin
          con.open_timeout = TIMEOUT
          response = con.get(camera.config['snapshots']['jpg'])
          if response
            Snapshot.create(
              camera: camera,
              created_at: instant,
              data: response.body,
              notes: params[:notes]
            )
            success = true
            break
          end
        rescue Net::OpenTimeout
          # offline
        rescue Exception => e
          # we weren't expecting this (famous last words)
          puts e
        end
      end
      success ? {message: 'Ok!'} : {message: 'Failed to save snapshot, all endpoints offline'}
    end

    desc 'Stores the supplied snapshot image data for the given timestamp (COMING SOON)'
    put '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

    desc 'Deletes any snapshot for this camera which exactly matches the timestamp (COMING SOON)'
    delete '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

  end
end

