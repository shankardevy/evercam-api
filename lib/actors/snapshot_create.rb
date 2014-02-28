# Disable File validation, it doesn't work
module Mutations
  class FileFilter < AdditionalFilter
      alias_method :filter_old, :filter

      def filter(data)
        [data, nil]
      end
  end
end

module Evercam
  module Actors
    class SnapshotCreate < Mutations::Command

      required do
        string :id
        integer :timestamp
        file :data, upload: true
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
        unless %w(image/jpeg image/pjpeg image/png image/x-png image/gif).include? inputs[:data]['type']
          add_error(:data, :valid, 'File type not supported')
        end

        Snapshot.create(
          camera: camera,
          created_at: Time.at(timestamp),
          data: inputs[:data]['tempfile'].read,
          notes: notes
        )
      end

    end
  end
end
