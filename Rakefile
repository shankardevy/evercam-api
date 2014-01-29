require 'rake'

require_relative './lib/config'
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

end

namespace :workers do

  require_relative './lib/workers'

  task :enable do
    Evercam::ScheduleWorker.enable
  end

  task :disable do
    Evercam::ScheduleWorker.disable
  end

  task :heartbeat do
    Evercam::HeartbeatWorker.run
  end

end

