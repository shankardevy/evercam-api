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

    desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
    post '/cameras/:id/snapshots' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      outcome = Actors::SnapshotFetch.run(params)
      raise OutcomeError, outcome unless outcome.success?

      present Array(outcome.result), with: Presenters::Snapshot
    end

    desc 'Stores the supplied snapshot image data for the given timestamp'
    put '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

    desc 'Deletes any snapshot for this camera which exactly matches the timestamp (COMING SOON)'
    delete '/cameras/:id/snapshots/:timestamp' do
      raise ComingSoonError
    end

  end
end

