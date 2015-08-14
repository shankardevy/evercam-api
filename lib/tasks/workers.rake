namespace :workers do

  Sequel.connect(Evercam::Config[:database])
  require 'evercam_models'
  require_relative '../workers'

  task :heartbeat do
    Evercam::HeartbeatWorker.enqueue_all
  end

  task :hb_single, [:arg1] do |t, args|
    Evercam::HeartbeatWorker.perform_async(args.arg1)
  end
end
