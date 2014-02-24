require_relative '../presenters/snapshot_presenter'

module Evercam
  class V1SnapshotRoutes < Grape::API

    include WebErrors

    desc 'Returns the list of all snapshots currently stored for this camera'
    get '/cameras/:id/snapshots' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      present camera.snapshots, with: Presenters::Snapshot, models: true
    end

    desc 'Returns the snapshot stored for this camera closest to the given timestamp', {
      entity: Evercam::Presenters::Snapshot
    }
    get '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      snap = Snapshot.by_ts!(Time.at(params[:timestamp].to_i))

      present Array(snap), with: Presenters::Snapshot, type: params[:type]
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
    post '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      outcome = Actors::SnapshotCreate.run(params)
      raise OutcomeError, outcome unless outcome.success?

      present Array(outcome.result), with: Presenters::Snapshot
    end

    desc 'Deletes any snapshot for this camera which exactly matches the timestamp'
    delete '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |r| camera.allow?(:edit, r) }

      Snapshot.by_ts!(Time.at(params[:timestamp].to_i)).destroy
      {}
    end

  end
end

