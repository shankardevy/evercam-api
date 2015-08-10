module Evercam
  module Actors
    class CloudRecordingUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        integer :frequency
        integer :storage_duration
        string :schedule
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])
        cloud_recording = CloudRecording.where(camera_id: camera.id).first
        add_error(:cloud_recording, :exists, "CloudRecording setting does not exist") if cloud_recording.blank?

        unless inputs["schedule"].blank?
          begin
            schedule = JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end

        cloud_recording.frequency = inputs["frequency"] unless inputs["frequency"].blank?
        cloud_recording.storage_duration = inputs["storage_duration"] unless inputs["storage_duration"].blank?
        cloud_recording.schedule = cloud_recording.schedule.merge(schedule)
        cloud_recording.save

        cloud_recording
      end
    end
  end
end
