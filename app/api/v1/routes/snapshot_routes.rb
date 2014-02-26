require_relative '../presenters/snapshot_presenter'

module Evercam
  class V1SnapshotSinatraRoutes < Sinatra::Base

    get '/cameras/:id/snapshot.jpg' do
      begin
        camera = ::Camera.by_exid!(params[:id])
      rescue NotFoundError => e
        halt 404, e.message
      end

      begin
        auth = WithAuth.new(env)
        auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }
      rescue AuthenticationError => e
        halt 401, e.message
      end

      response = nil

      camera.endpoints.each do |endpoint|
        next unless (endpoint.public? rescue false)
        con = Net::HTTP.new(endpoint.host, endpoint.port)

        begin
          con.open_timeout =  Evercam::Config[:api][:timeout]
          response = con.get(camera.config['snapshots']['jpg'])
          if response.is_a?(Net::HTTPSuccess)
            break
          end
        rescue Net::OpenTimeout
          # offline
        rescue Exception => e
          # we weren't expecting this (famous last words)
          puts e
        end
      end
      if response.is_a?(Net::HTTPSuccess)
        headers 'Content-Type' => 'image/jpg; charset=utf8'
        response.body
      else
        status 503
        'Camera offline'
      end
    end

  end

  class V1SnapshotRoutes < Grape::API

    include WebErrors

    desc 'Returns the list of all snapshots currently stored for this camera'
    get '/cameras/:id/snapshots' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

      present camera.snapshots, with: Presenters::Snapshot, models: true
    end

    desc 'Returns the snapshot stored for this camera closest to the given timestamp', {
      entity: Evercam::Presenters::Snapshot
    }
    get '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

      snap = Snapshot.by_ts!(Time.at(params[:timestamp].to_i))

      present Array(snap), with: Presenters::Snapshot, type: params[:type]
    end

    desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
    post '/cameras/:id/snapshots' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

      outcome = Actors::SnapshotFetch.run(params)
      raise OutcomeError, outcome unless outcome.success?

      present Array(outcome.result), with: Presenters::Snapshot
    end

    desc 'Stores the supplied snapshot image data for the given timestamp'
    post '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

      outcome = Actors::SnapshotCreate.run(params)
      raise OutcomeError, outcome unless outcome.success?

      present Array(outcome.result), with: Presenters::Snapshot
    end

    desc 'Deletes any snapshot for this camera which exactly matches the timestamp'
    delete '/cameras/:id/snapshots/:timestamp' do
      camera = ::Camera.by_exid!(params[:id])
      auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

      Snapshot.by_ts!(Time.at(params[:timestamp].to_i)).destroy
      {}
    end

  end
end

