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
      migration = 0
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

  Sequel.connect(Evercam::Config[:database])
  require 'evercam_models'
  require_relative 'lib/workers'

  task :heartbeat do
    Evercam::HeartbeatWorker.enqueue_all
  end

  task :hb_single, [:arg1] do |t, args|
    Evercam::HeartbeatWorker.perform_async(args.arg1)
  end
end

namespace :tmp do
  task :clear do
    require 'dalli'
    require_relative 'lib/services'

    Evercam::Services.dalli_cache.flush_all
    puts "Memcached cache flushed!"
  end
end

desc "Import cambase_models.csv from S3 and fix Evercam models data for given vendor onlys"
task :import_vendor_data, [:vendorexid] do |t, args|
  require 'evercam_models'
  require 'aws-sdk'
  require 'open-uri'
  require 'smarter_csv'

  AWS.config(
    :access_key_id => ENV['AWS_ACCESS_KEY_ID'], 
    :secret_access_key => ENV['AWS_SECRET_KEY'],
    # disable this key if source bucket is in US
    :s3_endpoint => 's3-eu-west-1.amazonaws.com'
  )
  s3 = AWS::S3.new
  assets = s3.buckets['evercam-public-assets']
  csv = assets.objects['models_data.csv']
  
  if csv.nil?
    puts " No CSV file found"
  else
    puts " CSV file found"
  end

  if !Dir.exists?("temp/")
    puts " Create temp/"
    Dir.mkdir("temp/")
  end

  puts "\n Importing models_data.csv... \n"
  File.open("temp/models_data.csv", "wb") do |f|
    f.write(csv.read)
    puts " 'models_data.csv' imported from AWS S3 \n"
  end
  
  puts "\n Reading data from 'models_data.csv' for #{args[:vendorexid]} \n"
  File.open("temp/models_data.csv", "r:ISO-8859-15:UTF-8") do |file|
    v = Vendor.find(:exid => args[:vendorexid])
    if v.nil?
      if args[:vendorexid] =~ /^[a-z0-9\-_]+$/ and args[:vendorexid].length > 3
        v = Vendor.new(
          exid: args[:vendorexid],
          name: args[:vendorexid].upcase,
          known_macs: ['']
        )
        v.save
        puts "    V += " + v.id.to_s + ", " + args[:vendorexid] + ", " + args[:vendorexid].upcase
      else
        puts ' Vendor ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.'
      end
    end
    d = VendorModel.find(exid: v.exid + "_default")
    if d.nil?
      d = VendorModel.new(
        exid: v.exid + "_default",
        name: "Default",
        vendor_id: v.id,
        config: {}
      )
      d.save
      puts "    D += " + d.exid.to_s + ", " + d.name
    else
      puts "    D == " + d.exid.to_s + ", " + d.name
    end

    SmarterCSV.process(file).each do |vm|
      next if !(vm[:vendor_id].downcase == args[:vendorexid].downcase)
      original_vm = vm.clone
      puts "    + " + v.exid + "." + vm[:model].to_s
      
      if !d.nil?
        Rake::Task["fix_model"].invoke(d, vm[:jpg_url], vm[:h264_url], vm[:mjpg_url], vm[:default_username], vm[:default_password])
      end

      m = VendorModel.where(:exid => vm[:model].to_s).first
      if m.nil?
        m = VendorModel.new(
            exid: vm[:model].to_s,
            name: vm[:model].upcase,
            vendor_id: v.id,
            config: {}
        )
        puts "     VM += " + v.id.to_s + ", " + vm[:model] + ", " + vm[:model].upcase
      else
        puts "     VM ^= " + m.vendor_id.to_s + ", " + m.exid + ", " + m.name
      end

      jpg_url = vm[:jpg_url].nil? ? "" : vm[:jpg_url]
      h264_url = vm[:h264_url].nil? ? "" : vm[:h264_url]
      mjpg_url = vm[:mjpg_url].nil? ? "" : vm[:mjpg_url]
      default_username = vm[:default_username].nil? ? "" : vm[:default_username].to_s
      default_password = vm[:default_password].nil? ? "" : vm[:default_password].to_s
      
      ### This does not call the method if any of the parameters is blank
      #Rake::Task["fix_model"].invoke(m, jpg_url, h264_url, mjpg_url, default_username, default_password)

      m.name = m.name.upcase

      if !jpg_url.blank?
        m.jpg_url = jpg_url 
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('jpg')
            m.values[:config]['snapshots']['jpg'] = jpg_url
          else
            m.values[:config]['snapshots'].merge!({:jpg => jpg_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :jpg => jpg_url}})
        end
      end

      if !h264_url.blank?
        m.h264_url = h264_url 
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('h264')
            m.values[:config]['snapshots']['h264'] = h264_url
          else
            m.values[:config]['snapshots'].merge!({:h264 => h264_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :h264 => h264_url}})
        end
      end

      if !mjpg_url.blank?
        m.mjpg_url = mjpg_url 
        if m.values[:config].has_key?('snapshots')
          if m.values[:config]['snapshots'].has_key?('mjpg')
            m.values[:config]['snapshots']['mjpg'] = mjpg_url
          else
            m.values[:config]['snapshots'].merge!({:mjpg => mjpg_url})
          end
        else
          m.values[:config].merge!({'snapshots' => { :mjpg => mjpg_url}})
        end
      end

      if default_username or default_password
        m.values[:config].merge!({'auth' => {'basic' => {'username' => default_username.to_s.empty? ? '' : default_username.to_s,
                                                         'password' => default_password.to_s.empty? ? '' : default_password.to_s}}})
      end

      puts "       " + m.values[:config].to_s

      ######
      m.save
      ######

      puts "       FIXED: #{m.exid}"
    end
  end
end


task :fix_model, [:m, :jpg_url, :h264_url, :mjpg_url, :default_username, :default_password] do |t, args|
  args.with_defaults(:jpg_url => "", :h264_url => "", :mjpg_url => "", :default_username => "", :default_password => "")

  m = args.m
  jpg_url = args.jpg_url.nil? ? "" : args.jpg_url
  h264_url = args.h264_url.nil? ? "" : args.h264_url
  mjpg_url = args.mjpg_url.nil? ? "" : args.mjpg_url
  default_username = args.default_username.nil? ? "" : args.default_username.to_s
  default_password = args.default_password.nil? ? "" : args.default_password.to_s
  
  m.name = m.name.upcase
  
  if !jpg_url.blank?
    m.jpg_url = jpg_url 
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('jpg')
        m.values[:config]['snapshots']['jpg'] = jpg_url
      else
        m.values[:config]['snapshots'].merge!({:jpg => jpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :jpg => jpg_url}})
    end
  end

  if !h264_url.blank?
    m.h264_url = h264_url 
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('h264')
        m.values[:config]['snapshots']['h264'] = h264_url
      else
        m.values[:config]['snapshots'].merge!({:h264 => h264_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :h264 => h264_url}})
    end
  end

  if !mjpg_url.blank?
    m.mjpg_url = mjpg_url 
    if m.values[:config].has_key?('snapshots')
      if m.values[:config]['snapshots'].has_key?('mjpg')
        m.values[:config]['snapshots']['mjpg'] = mjpg_url
      else
        m.values[:config]['snapshots'].merge!({:mjpg => mjpg_url})
      end
    else
      m.values[:config].merge!({'snapshots' => { :mjpg => mjpg_url}})
    end
  end

  if default_username or default_password
    m.values[:config].merge!({'auth' => {'basic' => {'username' => default_username.to_s.empty? ? '' : default_username.to_s,
                                                     'password' => default_password.to_s.empty? ? '' : default_password.to_s}}})
  end

  puts "       " + m.values[:config].to_s

  m.save

  puts "       FIXED: #{m.exid}"
end

task :fix_models_data do
  VendorModel.all.each do |model|
    updated = false
    ## Upcase all model names except Default
    if model.name.downcase != "default"
      if model.name != model.name.upcase
        model.name = model.name.upcase
        updated = true
      end
    end

    ## Remove None from model Urls
    if !model.jpg_url.blank? && (model.jpg_url.downcase == "none" || model.jpg_url.downcase == "jpg" || model.jpg_url.length < 4)
      model.jpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('jpg')
          model.values[:config]['snapshots']['jpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:jpg => ""})
          updated = true
        end
      end
    end
    if !model.h264_url.blank? && (model.h264_url.downcase == "none" || model.h264_url.downcase == "h264" || model.h264_url.length < 4)
      model.h264_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('h264')
          model.values[:config]['snapshots']['h264'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:h264 => ""})
          updated = true
        end
      end
    end
    if !model.mjpg_url.blank? && (model.mjpg_url.downcase == "none" || model.mjpg_url.downcase == "mjpg" || model.mjpg_url.length < 4)
      model.mjpg_url = ""
      if model.values[:config].has_key?('snapshots')
        if model.values[:config]['snapshots'].has_key?('mjpg')
          model.values[:config]['snapshots']['mjpg'] = ""
          updated = true
        else
          model.values[:config]['snapshots'].merge!({:mjpg => ""})
          updated = true
        end
      end
    end

    if updated
      puts " - " + model.name + ", " + model.exid
      model.save
    end
  end
end


task :import_cambase_data do
  file = File.read("models.json")

  models = JSON.parse(file)

  models.each do |model|
    vendor = Vendor.where(:exid => model['vendor_id']).first
    if vendor.nil?
      puts "Vendor #{model['vendor_id']} doesn't exist yet, creating it"
      vendor = Vendor.create(
        exid: model['vendor_id'],
        name: model['vendor_name'],
        known_macs: ['']
      )
    end

    vendor_model = VendorModel.where(:exid => model['id']).first
    if vendor_model.nil?
      puts "Model #{model['id']} doesn't exist yet, adding it"
      VendorModel.create(
        vendor_id: vendor.id,
        exid: model['id'],
        name: model['name'],
        config: model['config']
      )
    else
      puts "Model #{model['id']} already exist, skipping it"
    end
  end
end

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
