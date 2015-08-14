require 'rake'
require 'evercam_misc'
Dir.glob('lib/tasks/*.rake').each { |r| load r}


if :development == Evercam::Config.env
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :tmp do
  task :clear do
    require 'dalli'
    require_relative 'lib/services'

    Evercam::Services.dalli_cache.flush_all
    puts "Memcached cache flushed!"
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
