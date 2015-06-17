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

desc "Import models_data_all.csv from S3 and add extra specs data to Evercam Models"
task :import_vendor_models, [:vendorexid] do |t, args|
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
  csv = assets.objects['models_data_some.csv']

  if csv.nil?
    puts " No CSV file found"
  else
    puts " CSV file found"
  end

  if !Dir.exists?("temp/")
    puts " Create temp/"
    Dir.mkdir("temp/")
  end

  puts "\n Importing models_data_all.csv... \n"
  File.open("temp/models_data_all.csv", "wb") do |f|
    f.write(csv.read)
    puts " 'models_data.csv' imported from AWS S3 \n"
  end

  puts "\n Reading data from 'models_data_all.csv' for #{args[:vendorexid]} \n"
  File.open("temp/models_data_all.csv", "r:ISO-8859-15:UTF-8") do |file|
    v = Vendor.find(:exid => args[:vendorexid])
    if v.nil?
      puts " Vendor '" + args[:vendorexid] + "' could not be found"
      return
    end

    SmarterCSV.process(file).each do |vm|
      next if !(vm[:vendor_id].downcase == args[:vendorexid].downcase)
      original_vm = vm.clone
      puts "    + " + v.exid + "." + vm[:model].to_s

      m = VendorModel.where(:exid => vm[:model].to_s).first
      if m.nil?
        puts "     VM Not Found = " + v.id.to_s + ", " + vm[:model] + ", " + vm[:model].upcase
      else
        puts "     VM = " + m.vendor_id.to_s + ", " + m.exid + ", " + m.name
      end

      shape = vm[:shape].nil? ? "" : vm[:shape]
      resolution = vm[:resolution].nil? ? "" : vm[:resolution]
      official_url = vm[:official_url].nil? ? "" : vm[:official_url]
      audio_url = vm[:audio_url].nil? ? "" : vm[:audio_url]
      more_info = vm[:more_info].nil? ? "" : vm[:more_info]
      poe = vm[:poe].nil? ? "" : vm[:poe] == "t" ? "True" : "False"
      wifi = vm[:wifi].nil? ? "" : vm[:wifi] == "t" ? "True" : "False"
      onvif = vm[:onvif].nil? ? "" : vm[:onvif] == "t" ? "True" : "False"
      psia = vm[:psia].nil? ? "" : vm[:psia] == "t" ? "True" : "False"
      ptz = vm[:ptz].nil? ? "" : vm[:ptz] == "t" ? "True" : "False"
      infrared = vm[:infrared].nil? ? "" : vm[:infrared] == "t" ? "True" : "False"
      varifocal = vm[:varifocal].nil? ? "" : vm[:varifocal] == "t" ? "True" : "False"
      sd_card = vm[:sd_card].nil? ? "" : vm[:sd_card] == "t" ? "True" : "False"
      upnp = vm[:upnp].nil? ? "" : vm[:upnp] == "t" ? "True" : "False"
      audio_io = vm[:audio_io].nil? ? "" : vm[:audio_io] == "t" ? "True" : "False"
      discontinued = vm[:discontinued].nil? ? "" : vm[:discontinued] == "t" ? "True" : "False"

      puts "    SPEC = " + m.name
      Rake::Task["specs_model"].invoke(m, shape, resolution, official_url, audio_url, more_info, poe, wifi, onvif, psia, ptz, infrared, varifocal, sd_card, upnp, audio_io, discontinued)
    end
  end
end

# add specs to given model
task :specs_model, [:m, :shape, :resolution, :official_url, :audio_url, :more_info, :poe, :wifi, :onvif, :psia, :ptz, :infrared, :varifocal, :sd_card, :upnp, :audio_io, :discontinued] do |t, args|
  args.with_defaults(:shape => "", :resolution => "", :official_url => "", :audio_url => "", :more_info => "", :poe => "False", :wifi => "False", :onvif => "False", :psia => "False", :ptz => "False", :infrared => "False", :varifocal => "False", :sd_card => "False", :upnp => "False", :audio_io => "False", :discontinued => "False")

  m = args.m

  if !args.shape.nil?
    if m.values[:specs].has_key?('shape')
      m.values[:specs]['shape'] = args.shape
    else
      m.values[:specs].merge!({:shape => args.shape})
    end
  end
  puts "    - shape = " + m.values[:specs]['shape']

  if !args.resolution.nil?
    if m.values[:specs].has_key?('resolution')
      m.values[:specs]['resolution'] = args.resolution
    else
      m.values[:specs].merge!({:resolution => args.resolution})
    end
  end
  puts "    - resolution = " + m.values[:specs]['resolution']

  if !args.official_url.nil?
    if m.values[:specs].has_key?('official_url')
      m.values[:specs]['official_url'] = args.official_url
    else
      m.values[:specs].merge!({:official_url => args.official_url})
    end
  end
  puts "    - official_url = " + m.values[:specs]['official_url']

  if !args.audio_url.nil?
    if m.values[:specs].has_key?('audio_url')
      m.values[:specs]['audio_url'] = args.audio_url
    else
      m.values[:specs].merge!({:audio_url => args.audio_url})
    end
  end
  puts "    - audio_url = " + m.values[:specs]['audio_url']

  if !args.more_info.nil?
    if m.values[:specs].has_key?('more_info')
      m.values[:specs]['more_info'] = args.more_info
    else
      m.values[:specs].merge!({:more_info => args.more_info})
    end
  end
  puts "    - more_info = " + m.values[:specs]['more_info']

  if !args.poe.nil?
    if m.values[:specs].has_key?('poe')
      m.values[:specs]['poe'] = args.poe
    else
      m.values[:specs].merge!({:poe => args.poe})
    end
  end
  puts "    - poe = " + m.values[:specs]['poe']

  if !args.wifi.nil?
    if m.values[:specs].has_key?('wifi')
      m.values[:specs]['wifi'] = args.wifi
    else
      m.values[:specs].merge!({:wifi => args.wifi})
    end
  end
  puts "    - wifi = " + m.values[:specs]['wifi']

  if !args.onvif.nil?
    if m.values[:specs].has_key?('onvif')
      m.values[:specs]['onvif'] = args.onvif
    else
      m.values[:specs].merge!({:onvif => args.onvif})
    end
  end
  puts "    - onvif = " + m.values[:specs]['onvif']

  if !args.psia.nil?
    if m.values[:specs].has_key?('psia')
      m.values[:specs]['psia'] = args.psia
    else
      m.values[:specs].merge!({:psia => args.psia})
    end
  end
  puts "    - psia = " + m.values[:specs]['psia']

  if !args.ptz.nil?
    if m.values[:specs].has_key?('ptz')
      m.values[:specs]['ptz'] = args.ptz
    else
      m.values[:specs].merge!({:ptz => args.ptz})
    end
  end
  puts "    - ptz = " + m.values[:specs]['ptz']

  if !args.infrared.nil?
    if m.values[:specs].has_key?('infrared')
      m.values[:specs]['infrared'] = args.infrared
    else
      m.values[:specs].merge!({:infrared => args.infrared})
    end
  end
  puts "    - infrared = " + m.values[:specs]['infrared']

  if !args.varifocal.nil?
    if m.values[:specs].has_key?('varifocal')
      m.values[:specs]['varifocal'] = args.varifocal
    else
      m.values[:specs].merge!({:varifocal => args.varifocal})
    end
  end
  puts "    - varifocal = " + m.values[:specs]['varifocal']

  if !args.sd_card.nil?
    if m.values[:specs].has_key?('sd_card')
      m.values[:specs]['sd_card'] = args.sd_card
    else
      m.values[:specs].merge!({:sd_card => args.sd_card})
    end
  end
  puts "    - sd_card = " + m.values[:specs]['sd_card']

  if !args.upnp.nil?
    if m.values[:specs].has_key?('upnp')
      m.values[:specs]['upnp'] = args.upnp
    else
      m.values[:specs].merge!({:upnp => args.upnp})
    end
  end
  puts "    - upnp = " + m.values[:specs]['upnp']

  if !args.audio_io.nil?
    if m.values[:specs].has_key?('audio_io')
      m.values[:specs]['audio_io'] = args.audio_io
    else
      m.values[:specs].merge!({:audio_io => args.audio_io})
    end
  end
  puts "    - audio_io = " + m.values[:specs]['audio_io']

  if !args.discontinued.nil?
    if m.values[:specs].has_key?('discontinued')
      m.values[:specs]['discontinued'] = args.discontinued
    else
      m.values[:specs].merge!({:discontinued => args.discontinued})
    end
  end
  puts "    - discontinued = " + m.values[:specs]['discontinued']

  puts "       " + m.values[:specs].to_s

  ######
  m.save
  ######

  puts "       SPECS: #{m.exid}"
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
        m.values[:config].merge!({
          'auth' => {
            'basic' => {
              'username' => default_username.to_s.empty? ? '' : default_username.to_s,
              'password' => default_password.to_s.empty? ? '' : default_password.to_s
            }
          }
        })
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
    m.values[:config].merge!({
      'auth' => {
        'basic' => {
          'username' => default_username.to_s.empty? ? '' : default_username.to_s,
          'password' => default_password.to_s.empty? ? '' : default_password.to_s
        }
      }
    })
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

task :send_camera_data_to_elixir_server, [:total, :paid_only] do |t, args|
  Sequel.connect(Evercam::Config[:database])

  require 'active_support'
  require 'active_support/core_ext'
  require 'evercam_models'

  recording_cameras = [
    "dancecam",
    "centralbankbuild",
    "carrollszoocam",
    "gpocam",
    "wayra-agora",
    "wayrahikvision",
    "zipyard-navan-foh",
    "zipyard-ranelagh-foh",
    "gemcon-cathalbrugha",
    "smartcity1",
    "stephens-green",
    "treacyconsulting1",
    "treacyconsulting2",
    "treacyconsulting3",
    "dcctestdumpinghk",
    "beefcam1",
    "beefcam2",
    "beefcammobile",
    "bennett"
  ]
  begin
    total = args[:total] || Camera.count
    cameras = Camera
    cameras = cameras.where(exid: recording_cameras) if args[:paid_only].present?
    cameras.take(total.to_i).each do |camera|
      camera_url = camera.external_url.to_s
      camera_url << camera.res_url('jpg').to_s
      unless camera_url.blank?
        auth = "#{camera.cam_username}:#{camera.cam_password}"
        frequent = recording_cameras.include? camera.exid
        Sidekiq::Client.push({
          'queue' => "to_elixir",
          'class' => "ElixirWorker",
          'args' => [
            camera.exid,
            camera_url,
            auth,
            frequent
          ]
        })
      end
    end
  rescue Exception => e
    log.warn(e)
  end
end
