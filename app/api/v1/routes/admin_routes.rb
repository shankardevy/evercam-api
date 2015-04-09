# TODO: remove this after launching sidekiq-based system on the Elixir server
module Evercam
  class V1AdminRoutes < Grape::API
    format :json

    namespace :admin do
      #-------------------------------------------------------------------
      # POST /v1/admin/cameras/:id/recordings/snapshot/:timestamp
      #-------------------------------------------------------------------
      params do
        requires :id, type: String, desc: "Camera Id."
        requires :timestamp, type: Integer, desc: "Snapshot Unix timestamp."
      end
      desc 'Internal endpoint, keep hidden', {
        hidden: true
      }
      post 'cameras/:id/recordings/snapshot/:timestamp' do
        filepath = "#{params['id']}/snapshots/#{params['timestamp']}.jpg"
        file = Evercam::Services.snapshot_bucket.objects[filepath]

        raise NotFoundError.new unless file.exists?

        if Snapshot.where(created_at: Time.at(params['timestamp'])).all.blank?
          camera = get_cam(params[:id])
          Snapshot.create(
            camera: camera,
            created_at: Time.at(params['timestamp']),
            data: 'S3',
            notes: 'Evercam System'
          )
        end

        {}
      end
    end
  end
end
