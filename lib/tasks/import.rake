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
  csv = assets.objects['models_data_all.csv']

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
    puts " 'models_data_all.csv' imported from AWS S3 \n"
  end

  puts "\n Reading data from 'models_data_all.csv' for #{args[:vendorexid]} \n"
  File.open("temp/models_data_all.csv", "r:ISO-8859-15:UTF-8") do |file|
    v = Vendor.find(:exid => args[:vendorexid])
    if v.nil?
      # try creating new vendor if does not exist already
      if args[:vendorexid] =~ /^[a-z0-9\-_]+$/ and args[:vendorexid].length > 3
        v = Vendor.new(
          exid: args[:vendorexid],
          name: args[:vendorexid].upcase,
          known_macs: ['']
        )
        v.save
        puts "    V += " + v.id.to_s + ", " + args[:vendorexid] + ", " + args[:vendorexid].upcase
      else
        puts ' New vendor ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.'
      end
    else
      puts "    V == " + v.exid
    end
    d = VendorModel.find(exid: v.exid + "_default")
    if d.nil?
      # try creating default vendor model if does not exist already
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

      m = VendorModel.where(:exid => vm[:model].to_s).first

      # Next if vendor model not found
      next if m.nil?

      puts "    M == " + m.exid + ", " + m.name

      shape = vm[:shape].nil? ? "" : vm[:shape]
      resolution = vm[:resolution].nil? ? "" : vm[:resolution]
      official_url = vm[:official_url].nil? ? "" : vm[:official_url]
      audio_url = vm[:audio_url].nil? ? "" : vm[:audio_url]
      more_info = vm[:more_info].nil? ? "" : vm[:more_info]
      poe = vm[:poe].nil? ? "False" : vm[:poe] == "t" ? "True" : "False"
      wifi = vm[:wifi].nil? ? "False" : vm[:wifi] == "t" ? "True" : "False"
      onvif = vm[:onvif].nil? ? "False" : vm[:onvif] == "t" ? "True" : "False"
      psia = vm[:psia].nil? ? "False" : vm[:psia] == "t" ? "True" : "False"
      ptz = vm[:ptz].nil? ? "False" : vm[:ptz] == "t" ? "True" : "False"
      infrared = vm[:infrared].nil? ? "False" : vm[:infrared] == "t" ? "True" : "False"
      varifocal = vm[:varifocal].nil? ? "False" : vm[:varifocal] == "t" ? "True" : "False"
      sd_card = vm[:sd_card].nil? ? "False" : vm[:sd_card] == "t" ? "True" : "False"
      upnp = vm[:upnp].nil? ? "False" : vm[:upnp] == "t" ? "True" : "False"
      audio_io = vm[:audio_io].nil? ? "False" : vm[:audio_io] == "t" ? "True" : "False"
      discontinued = vm[:discontinued].nil? ? "False" : vm[:discontinued] == "t" ? "True" : "False"

      # set up specs
      m.values[:shape] = shape
      m.values[:resolution] = resolution
      m.values[:official_url] = official_url
      m.values[:poe] = poe
      m.values[:wifi] = wifi
      m.values[:onvif] = onvif
      m.values[:psia] = psia
      m.values[:ptz] = ptz
      m.values[:infrared] = infrared
      m.values[:varifocal] = varifocal
      m.values[:sd_card] = sd_card
      m.values[:upnp] = upnp
      m.values[:audio_io] = audio_io
      m.values[:discontinued] = discontinued

      # set up snapshot urls
      if m.values[:config].has_key?("snapshots")
        if m.values[:config]["snapshots"].has_key?("jpg")
          m.values[:jpg_url] = m.values[:config]["snapshots"]["jpg"]
        end
        if m.values[:config]["snapshots"].has_key?("h264")
          m.values[:h264_url] = m.values[:config]["snapshots"]["h264"]
        end
        if m.values[:config]["snapshots"].has_key?("mjpg")
          m.values[:mjpg_url] = m.values[:config]["snapshots"]["mjpg"]
        end
      end

      # set up basic auth
      if m.values[:config].has_key?("auth") && m.values[:config]["auth"].has_key?("basic")
        if m.values[:config]["auth"]["basic"].has_key?("username")
          m.values[:username] = m.values[:config]["auth"]["basic"]["username"]
        end
        if m.values[:config]["auth"]["basic"].has_key?("password")
          m.values[:password] = m.values[:config]["auth"]["basic"]["password"]
        end
      end

      ######
      m.save
      ######

      puts "      => " + m.exid + ", " + m.name
    end
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
