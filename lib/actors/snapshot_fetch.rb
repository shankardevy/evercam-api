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

        camera.endpoints.each do |endpoint|
          next unless (endpoint.public? rescue false)
          con = Net::HTTP.new(endpoint.host, endpoint.port)

          begin
            con.open_timeout = Evercam::Config[:api][:timeout]
            response = con.get(camera.config['snapshots']['jpg'])
            if response.is_a?(Net::HTTPSuccess)
              snapshot = Snapshot.create(
                camera: camera,
                created_at: instant,
                data: response.body,
                notes: inputs[:notes]
              )
              break
            end
          rescue Net::OpenTimeout
            # offline
          rescue Exception => e
            # we weren't expecting this (famous last words)
            puts e
          end
        end

        if snapshot.nil?
          add_error(:camera, :offline, 'Camera is offline')
        end

        snapshot
      end

    end
  end
end
