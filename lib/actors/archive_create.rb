module Evercam
  module Actors
    class ArchiveCreate < Mutations::Command

      required do
        string :id
        string :title
        integer :from_date
        integer :to_date
        string :requested_by
      end

      optional do
        boolean :embed_time
        boolean :public
      end

      def validate
        if Time.now <= Time.at(from_date)
          add_error(:from_date, :valid, 'From date cannot be greater than current time.')
        end
        if Time.now <= Time.at(to_date)
          add_error(:to_date, :valid, 'To date cannot be greater than current time.')
        end
        if Time.at(to_date) < Time.at(from_date)
          add_error(:to_date, :valid, 'To date cannot be less than from date.')
        end
        if Time.at(from_date).eql?(Time.at(to_date))
          add_error(:to_date, :valid, 'To date and from date cannot be same.')
        end
      end

      def execute
        camera = Camera.where(exid: inputs[:id])
        raise Evercam::ConflictError.new("A camera with the id '#{inputs[:id]}' already exists.",
                                           "duplicate_camera_id_error", inputs[:id]) if camera.count == 0

        user = User.by_login(inputs[:requested_by])
        raise NotFoundError.new("Unable to locate a user for '#{inputs[:requested_by]}'.",
                                "user_not_found_error", inputs[:requested_by]) if user.nil?

        clip_exid = title.downcase.gsub(' ','')
        chars = [('a'..'z'), (0..9)].flat_map { |i| i.to_a }
        random_string = (0...3).map { chars[rand(chars.length)] }.join
        clip_exid = "#{clip_exid[0..5]}-#{random_string}"

        archive = Archive.new(
          camera: camera,
          exid: clip_exid,
          title: title,
          from_date: Time.at(from_date),
          to_date: Time.at(to_date),
          status: Archive::PENDING,
          user: user
        )

        archive.embed_time = embed_time if embed_time
        archive.public = public if public
        archive.save

        archive
      end
    end
  end
end