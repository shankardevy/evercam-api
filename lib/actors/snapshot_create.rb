module Evercam
  module Actors
    class SnapshotCreate < Mutations::Command

      required do
        string :id
        integer :timestamp
        file :data
      end

      optional do
        string :notes
      end

      def validate
        if Snapshot.by_ts(Time.at(timestamp.to_i))
          add_error(:snapshot, :exists, 'Snapshot for this timestamp already exists')
        end
      end

      def execute
        camera = ::Camera.by_exid!(id)
        puts 'DATA:'
        puts data[0,4]

        Snapshot.create(
          camera: camera,
          created_at: Time.at(timestamp),
          data: data,
          notes: notes
        )
      end

    end
  end
end
