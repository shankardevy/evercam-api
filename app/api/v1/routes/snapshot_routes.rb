module Evercam
  class V1SnapshotRoutes < Grape::API

    include WebErrors

    desc 'Returns the list of all snapshots currently stored for this camera (COMING SOON)'
    get '/cameras/:id/snapshots' do
      raise ComingSoonError
    end

    desc 'Returns the snapshot stored for this camera closest to the given timestamp (COMING SOON)'
    get '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

    desc 'Fetches a snapshot from the camera and stores it using the current timestamp (COMING SOON)'
    post '/cameras/:id/snapshots' do
      raise ComingSoonError
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

