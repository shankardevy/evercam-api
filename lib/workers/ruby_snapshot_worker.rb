require 'aws'
require_relative '../../lib/services'

module Evercam
  class RubySnapshotWorker

    include Sidekiq::Worker

    sidekiq_options queue: :from_elixir

    def perform(camera_id, timestamp)
      filepath = "#{camera_id}/snapshots/#{timestamp}.jpg"
      file = Evercam::Services.snapshot_bucket.objects[filepath]

      raise NotFoundError.new(
        "File '#{filepath}' not found in '#{Evercam::Services.snapshot_bucket.name}' bucket"
      ) unless file.exists?

      if Snapshot.where(created_at: Time.at(timestamp)).all.blank?
        camera = Camera.by_exid!(camera_id)
        Snapshot.create(
          camera: camera,
          created_at: Time.at(timestamp),
          data: 'S3',
          notes: 'Evercam Proxy'
        )
      end
    end
  end
end
