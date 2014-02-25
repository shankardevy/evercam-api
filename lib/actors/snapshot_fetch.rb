module Evercam
  module Actors
    class SnapshotFetch < Mutations::Command

      TIMEOUT = 5

      required do
        string :id
      end

      optional do
        string :notes
      end

      def execute
        instant = Time.now
        camera = ::Camera.by_exid!(inputs[:id])
        snapshot = nil

        camera.endpoints.each do |endpoint|
          next unless (endpoint.public? rescue false)
          con = Net::HTTP.new(endpoint.host, endpoint.port)

          begin
            con.open_timeout = TIMEOUT
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

        snapshot
      end

    end
  end
end
