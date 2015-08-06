module Evercam
  module Actors
    class CloudRecordingCreate < Mutations::Command

      required do
        string :id
      end

      optional do
        integer :storage_duration
        string :schedule
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])

        if inputs["schedule"].blank?
          schedule = {}
        else
          begin
            schedule = JSON.parse(inputs["schedule"])
          rescue => _e
            add_error(:schedule, :invalid, "The parameter 'schedule' isn't formatted as a proper JSON.")
          end
        end

        cloud_recording = CloudRecording.where(camera_id: camera.id).first

        if cloud_recording.blank?
          CloudRecording.create(
            camera_id: camera.id,
            storage_duration: inputs["storage_duration"],
            schedule: schedule
          )
        else
          cloud_recording.update(
            storage_duration: inputs["storage_duration"],
            schedule: schedule
          )
          cloud_recording
        end
      end
    end
  end
end
