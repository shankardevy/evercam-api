namespace :db do
  require 'sequel'
  Sequel.extension :migration, :pg_json, :pg_array

  task :migrate do
    envs = [Evercam::Config.env]
    envs << :test if :development == envs[0]
    envs.each do |env|
      dbName = Evercam::Config.settings[env][:database]
      puts "migrate: #{env} with databse name #{dbName}"
      db = Sequel.connect(dbName)
      Sequel::Migrator.run(db, 'migrations')
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

  task :seed do
    country = Country.create(iso3166_a2: "ad", name: "Andorra")

    user = User.create(
      username: "dev",
      password: "dev",
      firstname: "Awesome",
      lastname: "Dev",
      email: "dev@localhost.dev",
      country_id: country.id,
      api_id: SecureRandom.hex(4),
      api_key: SecureRandom.hex
    )

    hikvision_vendor = Vendor.create(
      exid: "hikvision",
      known_macs: ["00:0C:43", "00:40:48", "8C:E7:48", "00:3E:0B", "44:19:B7"],
      name: "Hikvision Digital Technology"
    )

    hikvision_model = VendorModel.create(
      vendor_id: hikvision_vendor.id,
      name: "Default",
      config: {
        "auth" => {
          "basic" => {
            "username" => "admin",
            "password" => "12345"
          }
        },
        "snapshots" => {
          "h264" => "h264/ch1/main/av_stream",
          "lowres" => "",
          "jpg" => "Streaming/Channels/1/picture",
          "mpeg4" => "mpeg4/ch1/main/av_stream",
          "mobile" => "",
          "mjpg" => ""
        }
      },
      exid: "hikvision_default",
      jpg_url: "Streaming/Channels/1/picture",
      h264_url: "h264/ch1/main/av_stream",
      mjpg_url: "",
      shape: "Dome",
      resolution: "640x480",
      official_url: "",
      audio_url: "",
      more_info: "",
      poe: true,
      wifi: false,
      onvif: true,
      psia: true,
      ptz: false,
      infrared: true,
      varifocal: true,
      sd_card: false,
      upnp: false,
      audio_io: true,
      discontinued: false,
      username: "admin",
      password: "12345"
    )

    Camera.create(
      name: "Hikvision Devcam",
      exid: "hikvision_devcam",
      owner_id: user.id,
      is_public: false,
      model_id: hikvision_model.id,
      config: {
        "internal_rtsp_port" => "",
        "internal_http_port" => "",
        "internal_host" => "",
        "external_rtsp_port" => 9101,
        "external_http_port" => 8101,
        "external_host" => "5.149.169.19",
        "snapshots" => {
          "jpg" => "/Streaming/Channels/1/picture"
        },
        "auth" => {
          "basic" => {
            "username" => "admin",
            "password" => "mehcam"
          }
        }
      }
    )

    Camera.create(
      name: "Y-cam DevCam",
      exid: "y_cam_devcam",
      owner_id: user.id,
      is_public: false,
      config: {
        "internal_rtsp_port" => "",
        "internal_http_port" => "",
        "internal_host" => "",
        "external_rtsp_port" => "",
        "external_http_port" => 8013,
        "external_host" => "5.149.169.19",
        "snapshots" => {
          "jpg" => "/snapshot.jpg"
        },
        "auth" => {
          "basic" => {
            "username" => "",
            "password" => ""
          }
        }
      }
    )

    Camera.create(
      name: "Evercam Devcam",
      exid: "evercam-remembrance-camera-0",
      owner_id: user.id,
      is_public: true,
      model_id: hikvision_model.id,
      config: {
        "internal_rtsp_port" => 0,
        "internal_http_port" => 0,
        "internal_host" => "",
        "external_rtsp_port" => 90,
        "external_http_port" => 80,
        "external_host" => "149.5.38.22",
        "snapshots" => {
          "jpg" => "/Streaming/Channels/1/picture"
        },
        "auth" => {
          "basic" => {
            "username" => "guest",
            "password" => "guest"
          }
        }
      }
    )
  end
end
