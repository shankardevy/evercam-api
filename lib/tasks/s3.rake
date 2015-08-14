task :export_snapshots_to_s3 do

  Sequel.connect(Evercam::Config[:database])

  require 'evercam_models'
  require 'aws-sdk'

  begin
    Snapshot.set_primary_key :id

    Snapshot.where(notes: "Evercam Capture auto save").or("notes IS NULL").each do |snapshot|
      puts "S3 export: Started migration for snapshot #{snapshot.id}"
      camera = snapshot.camera
      filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"

      unless snapshot.data == 'S3'
        Evercam::Services.snapshot_bucket.objects.create(filepath, snapshot.data)

        snapshot.data = 'S3'
        snapshot.save
      end

      puts "S3 export: Snapshot #{snapshot.id} from camera #{camera.exid} moved to S3"
      puts "S3 export: #{Snapshot.where(notes: "Evercam Capture auto save").or("notes IS NULL").count} snapshots left \n\n"
    end

  rescue Exception => e
    log.warn(e)
  end
end

task :export_thumbnails_to_s3 do
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'
  require 'aws-sdk'

  begin
    Camera.each do |camera|
      filepath = "#{camera.exid}/snapshots/latest.jpg"

      unless camera.preview.blank?
        Evercam::Services.snapshot_bucket.objects.create(filepath, camera.preview)
        image = Evercam::Services.snapshot_bucket.objects[filepath]
        camera.thumbnail_url = image.url_for(:get, {expires: 10.years.from_now, secure: true}).to_s
        camera.save

        puts "S3 export: Thumbnail for camera #{camera.exid} exported to S3"
      end
    end

  rescue Exception => e
    log.warn(e)
  end
end
