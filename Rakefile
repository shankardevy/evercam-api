require 'rake'
require_relative './lib/config'

if :development == Evercam::Config.env
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :db do

  require 'sequel'
  namespace :migrate do

    Sequel.extension :migration, :pg_json, :pg_array

    task :up do
      db = Sequel.connect(Evercam::Config[:database])
      Sequel::Migrator.run(db, 'migrations')
    end

  end

end

namespace :schedule do

  require_relative './lib/workers'
  require_relative './lib/models'
  db = Sequel::Model.db

  task :minute do
    cameras = db[:streams]
    cameras.select(:name).each do |row|
      HeartBeatWorker.perform_async(row[:name])
    end


  end

end
