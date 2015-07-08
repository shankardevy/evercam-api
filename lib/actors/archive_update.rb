module Evercam
  module Actors
    class ArchiveUpdate < Mutations::Command

      required do
        string :id
        string :archive_id
      end

      optional do
        string :title
        boolean :public
      end

      def validate
        if Archive.where(exid: inputs[:archive_id]).count == 0
          add_error(:archive_id, :valid, "The '#{inputs[:archive_id]}' archive does not exist.")
        end
      end

      def execute
        archive = ::Archive.where(exid: inputs[:archive_id]).first
        archive.title = title if title
        archive.public = public if public
        archive.save

        archive
      end
    end
  end
end