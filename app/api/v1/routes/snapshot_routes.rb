require_relative '../presenters/snapshot_presenter'

# Disable File validation, it doesn't work
module Grape
  module Validations
    class CoerceValidator < SingleOptionValidator
      alias_method :validate_param_old!, :validate_param!

      def validate_param!(attr_name, params)
        unless @option.to_s == 'File'
          validate_param_old!(attr_name, params)
        end

      end
    end
  end
end

module Evercam
  class V1SnapshotJpgRoutes < Grape::API
    content_type :img, "image/jpg"
    formatter :img, lambda { |object, env| object.body }
    format :img

    include WebErrors

    namespace :cameras do
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do
        desc 'Returns jpg from the camera'
        get 'snapshot.jpg' do
          camera = ::Camera.by_exid!(params[:id])

          auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

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
            response
          else
            raise CameraOfflineError, 'Camera offline'
          end
        end
      end
    end


  end

  class V1SnapshotRoutes < Grape::API

    include WebErrors

    namespace :cameras do
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do

        desc 'Returns the list of all snapshots currently stored for this camera'
        get 'snapshots' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

          present camera.snapshots, with: Presenters::Snapshot, models: true
        end

        desc 'Returns latest snapshot stored for this camera', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          optional :with_data, type: Boolean, desc: "Should it send image data?"
        end
        get 'snapshots/latest' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

          snap = camera.snapshots.order(:created_at).last

          present Array(snap), with: Presenters::Snapshot, with_data: params[:with_data]
        end

        desc 'Returns the snapshot stored for this camera closest to the given timestamp', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
          optional :with_data, type: Boolean, desc: "Should it send image data?"
          optional :range, type: Integer, desc: "Time range in seconds around specified timestamp"
        end
        get 'snapshots/:timestamp' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::SNAPSHOT, token) }

          snap = camera.snapshot_by_ts!(Time.at(params[:timestamp].to_i), params[:range].to_i)

          present Array(snap), with: Presenters::Snapshot, with_data: params[:with_data]
        end

        desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
        params do
          optional :notes, type: String, desc: "Optional text note for this snapshot"
        end
        post 'snapshots' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

          outcome = Actors::SnapshotFetch.run(params)
          raise OutcomeError, outcome unless outcome.success?

          present Array(outcome.result), with: Presenters::Snapshot
        end

        desc 'Stores the supplied snapshot image data for the given timestamp'
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
          requires :data, type: File, desc: "Image file."
          optional :notes, type: String, desc: "Optional text note for this snapshot"
        end
        post 'snapshots/:timestamp' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

          outcome = Actors::SnapshotCreate.run(params)
          raise OutcomeError, outcome unless outcome.success?

          present Array(outcome.result), with: Presenters::Snapshot
        end

        desc 'Deletes any snapshot for this camera which exactly matches the timestamp'
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
        end
        delete 'snapshots/:timestamp' do
          camera = ::Camera.by_exid!(params[:id])
          auth.allow? { |token| camera.allow?(AccessRight::EDIT, token) }

          camera.snapshot_by_ts!(Time.at(params[:timestamp].to_i)).destroy
          {}
        end

      end
    end

  end
end

