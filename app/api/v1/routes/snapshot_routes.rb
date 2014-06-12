require 'typhoeus'
require_relative '../presenters/snapshot_presenter'

module Evercam

  def self.get_jpg(camera)
    response = nil

    unless camera.external_url.nil?
      begin
        auth = camera.config.fetch('auth', {}).fetch('basic', '')
        if auth != ''
          auth = "#{camera.config['auth']['basic']['username']}:#{camera.config['auth']['basic']['password']}"
        end
        response  = Typhoeus::Request.get(camera.external_url + camera.config['snapshots']['jpg'],
                                          userpwd: auth,
                                          timeout: Evercam::Config[:api][:timeout],
                                          connecttimeout: Evercam::Config[:api][:timeout])
      rescue URI::InvalidURIError
        raise BadRequestError, 'Invalid URL'
      end
    end

    if response.nil?
      raise CameraOfflineError, 'No public endpoint'
    elsif response.success?
      response
    elsif response.code == 401
      raise AuthorizationError, 'Please check camera username and password'
    else
      raise CameraOfflineError, 'Camera offline'
    end
  end

  class V1SnapshotJpgRoutes < Grape::API
    format :json

    namespace :cameras do
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do
        desc 'Returns jpg from the camera'
        get 'snapshot.jpg' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new if !rights.allow?(AccessRight::SNAPSHOT)

          unless camera.external_url.nil?
            require 'openssl'
            require 'base64'
            auth = camera.config.fetch('auth', {}).fetch('basic', '')
            if auth != ''
              auth = "#{camera.config['auth']['basic']['username']}:#{camera.config['auth']['basic']['password']}"
            end
            c = OpenSSL::Cipher::Cipher.new("aes-256-cbc")
            c.encrypt
            c.key = "#{Evercam::Config[:snapshots][:key]}"
            c.iv = "#{Evercam::Config[:snapshots][:iv]}"
            # Padding was incompatible with node padding
            c.padding = 0
            msg = camera.external_url
            msg << camera.jpg_url unless camera.jpg_url.nil?
            msg << "|#{auth}|#{Time.now.to_s}|"
            until msg.length % 16 == 0 do
              msg << ' '
            end
            t = c.update(msg)
            t << c.final

            CameraActivity.create(
              camera: camera,
              access_token: access_token,
              action: 'viewed',
              done_at: Time.now,
              ip: request.ip
            )

            redirect "#{Evercam::Config[:snapshots][:url]}#{camera.exid}.jpg?t=#{Base64.strict_encode64(t)}"
          end
        end
      end
    end


  end

  class V1SnapshotRoutes < Grape::API

    include WebErrors
    before do
      authorize!
    end

    DEFAULT_LIMIT_WITH_DATA = 10
    DEFAULT_LIMIT_NO_DATA = 100

    namespace :cameras do
      params do
        requires :id, type: String, desc: "Camera Id."
      end
      route_param :id do

        desc 'Returns base64 encoded jpg from the camera'
        get 'live' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new if !rights.allow?(AccessRight::SNAPSHOT)
          res = Evercam::get_jpg(camera)
          data = Base64.encode64(res.body).gsub("\n", '')
          {
            camera: camera.exid,
            created_at: Time.now.to_i,
            timezone: camera.timezone.zone,
            data: "data:image/jpeg;base64,#{data}"
          }
        end

        desc 'Returns the list of all snapshots currently stored for this camera'
        get 'snapshots' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

          present camera.snapshots, with: Presenters::Snapshot, models: true
        end

        desc 'Returns latest snapshot stored for this camera', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          optional :with_data, type: 'Boolean', desc: "Should it send image data?"
        end
        get 'snapshots/latest' do
          camera   = ::Camera.by_exid!(params[:id])
          snapshot = camera.snapshots.order(:created_at).last
          if snapshot
            rights = requester_rights_for(snapshot)
            raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)
            present Array(snapshot), with: Presenters::Snapshot, with_data: params[:with_data]
          else
            present [], with: Presenters::Snapshot, with_data: params[:with_data]
          end
        end

        desc 'Returns list of snapshots between two timestamps'
        params do
          requires :from, type: Integer, desc: "From Unix timestamp."
          requires :to, type: Integer, desc: "To Unix timestamp."
          optional :with_data, type: 'Boolean', desc: "Should it send image data?"
          optional :limit, type: Integer, desc: "Limit number of results, default 100 with no data, 10 with data"
          optional :page, type: Integer, desc: "Page number"
        end
        get 'snapshots/range' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

          from = Time.at(params[:from].to_i).to_s
          to = Time.at(params[:to].to_i).to_s

          limit = params[:limit]
          if params[:with_data]
            limit ||= DEFAULT_LIMIT_WITH_DATA
          else
            limit ||= DEFAULT_LIMIT_NO_DATA
          end

          offset = 0
          if params[:page]
            offset = (params[:page] - 1) * limit
          end

          snap = camera.snapshots.order(:created_at).filter(:created_at => (from..to)).limit(limit).offset(offset)

          present Array(snap), with: Presenters::Snapshot, with_data: params[:with_data]
        end

        desc 'Returns list of specific days in a given month which contains any snapshots'
        params do
          requires :year, type: Integer, desc: "Year, for example 2013"
          requires :month, type: Integer, desc: "Month, for example 11"
        end
        get 'snapshots/:year/:month/days' do
          unless (1..12).include?(params[:month])
            raise BadRequestError, 'Invalid month value'
          end
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

          days = []
          (1..Date.new(params[:year], params[:month], -1).day).each do |day|
            from = camera.timezone.time(Time.utc(params[:year], params[:month], day)).to_s
            to = camera.timezone.time(Time.utc(params[:year], params[:month], day, 23, 59, 59)).to_s
            if camera.snapshots.filter(:created_at => (from..to)).count > 0
              days << day
            end
          end

          { :days => days}
        end

        desc 'Returns list of specific hours in a given day which contains any snapshots'
        params do
          requires :year, type: Integer, desc: "Year, for example 2013"
          requires :month, type: Integer, desc: "Month, for example 11"
          requires :day, type: Integer, desc: "Day, for example 17"
        end
        get 'snapshots/:year/:month/:day/hours' do
          unless (1..12).include?(params[:month])
            raise BadRequestError, 'Invalid month value'
          end
          unless (1..31).include?(params[:day])
            raise BadRequestError, 'Invalid day value'
          end
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

          hours = []
          (0..23).each do |hour|
            from = camera.timezone.time(Time.utc(params[:year], params[:month], params[:day], hour)).to_s
            to = camera.timezone.time(Time.utc(params[:year], params[:month], params[:day], hour, 59, 59)).to_s
            if camera.snapshots.filter(:created_at => (from..to)).count > 0
              hours << hour
            end
          end

          { :hours => hours}
        end

        desc 'Returns the snapshot stored for this camera closest to the given timestamp', {
          entity: Evercam::Presenters::Snapshot
        }
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
          optional :with_data, type: 'Boolean', desc: "Should it send image data?"
          optional :range, type: Integer, desc: "Time range in seconds around specified timestamp"
        end
        get 'snapshots/:timestamp' do
          camera = ::Camera.by_exid!(params[:id])

          snapshot = camera.snapshot_by_ts!(Time.at(params[:timestamp].to_i), params[:range].to_i)
          rights   = requester_rights_for(snapshot)
          raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

          present Array(snapshot), with: Presenters::Snapshot, with_data: params[:with_data]
        end

        desc 'Fetches a snapshot from the camera and stores it using the current timestamp'
        params do
          optional :notes, type: String, desc: "Optional text note for this snapshot"
        end
        post 'snapshots' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera)
          raise AuthorizationError.new if !rights.allow?(AccessRight::SNAPSHOT)

          outcome = Actors::SnapshotFetch.run(params)
          raise OutcomeError, outcome unless outcome.success?

          CameraActivity.create(
            camera: camera,
            access_token: access_token,
            action: 'captured',
            done_at: Time.now,
            ip: request.ip
          )

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

          rights = requester_rights_for(camera)
          raise AuthorizationError.new if !rights.allow?(AccessRight::SNAPSHOT)

          outcome = Actors::SnapshotCreate.run(params)
          raise OutcomeError, outcome unless outcome.success?

          CameraActivity.create(
            camera: camera,
            access_token: access_token,
            action: 'captured',
            done_at: Time.now,
            ip: request.ip
          )

          present Array(outcome.result), with: Presenters::Snapshot
        end

        desc 'Deletes any snapshot for this camera which exactly matches the timestamp'
        params do
          requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
        end
        delete 'snapshots/:timestamp' do
          camera = ::Camera.by_exid!(params[:id])

          rights = requester_rights_for(camera.owner, AccessRight::SNAPSHOTS)
          raise AuthorizationError.new if !rights.allow?(AccessRight::DELETE)

          CameraActivity.create(
            camera: camera,
            access_token: access_token,
            action: 'deleted snapshot',
            done_at: Time.now,
            ip: request.ip
          )

          camera.snapshot_by_ts!(Time.at(params[:timestamp].to_i)).destroy
          {}
        end

      end
    end

  end
end

