module Evercam
  module Actors
    class AppUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        boolean :local_recording
        boolean :cloud_recording
        boolean :motion_detection
        boolean :watermark
      end

      def execute
        camera = Camera.by_exid!(inputs[:id])
        apps = App.where(camera_id: camera.id).first
        apps = App.create(camera_id: camera.id) if apps.blank?

        apps.cloud_recording = inputs[:cloud_recording] unless inputs[:cloud_recording].nil?

        add_error(:local_recording, :valid, "The 'local_recording' app isn't implemented yet.") unless inputs[:local_recording].nil?
        add_error(:motion_detection, :valid, "The 'motion_detection' app isn't implemented yet.") unless inputs[:motion_detection].nil?
        add_error(:watermark, :valid, "The 'watermark' app isn't implemented yet.") unless inputs[:watermark].nil?

        apps.save
        apps
      end
    end
  end
end
