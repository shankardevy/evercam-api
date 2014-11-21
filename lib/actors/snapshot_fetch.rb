module Evercam
  module Actors
    class SnapshotFetch < Mutations::Command

      required do
        string :id
      end

      optional do
        string :notes
      end

      def execute
        camera = ::Camera.by_exid!(inputs[:id])
        instant = camera.timezone.time Time.now
        snapshot = nil
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
            if response.success?
              filepath = "#{camera.exid}/snapshots/#{instant.to_i}.jpg"
              Evercam::Services::s3_bucket.objects.create(filepath, response.body)

              snapshot = Snapshot.create(
                camera: camera,
                created_at: instant,
                data: 'S3',
                notes: inputs[:notes]
              )
            end
          rescue URI::InvalidURIError, Addressable::URI::InvalidURIError
            raise BadRequestError, 'Invalid URL'
          end
        end

        if response.nil?
          raise CameraOfflineError, 'No public endpoint'
        elsif response.code == 401
          raise AuthorizationError, 'Please check camera username and password'
        end

        if snapshot.nil?
          add_error(:camera, :offline, 'Camera is offline')
        end

        snapshot
      end

    end
  end
end
