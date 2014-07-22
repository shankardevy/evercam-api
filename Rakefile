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

