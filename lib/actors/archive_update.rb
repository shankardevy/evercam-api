module Evercam
  module Actors
    class ArchiveUpdate < Mutations::Command

      required do
        string :id
        string :archive_id
      end

      optional do
        string :title
        integer :status
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
        if status
          if status.eql? (Archive::PENDING)
            archive.status = Archive::PENDING
          elsif status.equal?(Archive::PROCESSING)
            archive.status = Archive::PROCESSING
          elsif status.equal?(Archive::COMPLETED)
            archive.status = Archive::COMPLETED
          elsif status.equal?(Archive::FAILED)
            archive.status = Archive::FAILED
          end
        end
        archive.save

        archive
      end
    end
  end
end