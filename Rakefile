require 'rake'
require 'evercam_misc'

if :development == Evercam::Config.env
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :db do

  require 'sequel'
  Sequel.extension :migration, :pg_json, :pg_array

  task :migrate do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db = Sequel.connect(Evercam::Config.settings[env][:database])
      Sequel::Migrator.run(db, 'migrations')
      puts "migrate: #{env}"
    end
  end

  task :rollback do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      db = Sequel.connect(Evercam::Config.settings[env][:database])
      migrations = db[:schema_migrations].order(:filename).to_a
      migration  = 0
      if migrations.length > 1
        match = /^(\d+).+$/.match(migrations[-2][:filename])
        migration = match[1].to_i if match
      end

      Sequel::Migrator.run(db, 'migrations', target: migration)
      puts "migrate: #{env}, ('#{migration}')"
    end
  end

end

namespace :workers do

  db = Sequel.connect(Evercam::Config[:database])
  require 'evercam_models'
  require_relative 'lib/workers'

  task :enable do
    Evercam::ScheduleWorker.enable
  end

  task :disable do
    Evercam::ScheduleWorker.disable
  end

  task :heartbeat do
    Evercam::HeartbeatWorker.run
  end

  task :hb_single, [:arg1] do |t, args|
    Evercam::HeartbeatWorker.perform_async(args.arg1)
  end

end

namespace :tmp do
  task :clear do
    require 'dalli'
    dc = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(','), :username => ENV["MEMCACHEDCLOUD_USERNAME"], :password => ENV["MEMCACHEDCLOUD_PASSWORD"])
    dc.flush_all
  end
end


task :export_snapshots_to_s3 do

  db = Sequel.connect(Evercam::Config[:database])

  require 'evercam_models'
  require 'aws-sdk'

  begin

    Snapshot.exclude(notes: "Evercam System").each do |snapshot|
      puts "S3 export: Started migration for snapshot #{snapshot.id}"
      camera = snapshot.camera
      filepath = "#{camera.exid}/snapshots/#{snapshot.created_at.to_i}.jpg"

      return if snapshot.data == 'S3'

      s3 = AWS::S3.new(:access_key_id => Evercam::Config[:amazon][:access_key_id], :secret_access_key => Evercam::Config[:amazon][:secret_access_key])
      @s3_bucket = s3.buckets['evercam-camera-assets']
      @s3_bucket.objects.create(filepath, snapshot.data)

      snapshot.notes = 'Evercam System'
      snapshot.data  = 'S3'
      snapshot.save

      puts "S3 export: Snapshot #{snapshot.id} from camera #{camera.exid} moved to S3"
      puts "S3 export: #{Snapshot.exclude(notes: "Evercam System").select(:id).count} snapshots left \n\n"
    end

  rescue Exception => e
    log.warn(e)
  end
end
