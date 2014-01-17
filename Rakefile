require 'rake'
require_relative './lib/config'
require 'rspec' rescue nil

if defined?(RSpec)
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :db do

  require 'sequel'
  namespace :migrate do

    Sequel.extension :migration
    DB = Sequel.connect(Evercam::Config[:database])
    MIGRATIONS = 'migrations'

    task :up do
      Sequel::Migrator.run(DB, MIGRATIONS)
    end

    task :down do
      Sequel::Migrator.run(DB, MIGRATIONS, :target => 0)
    end

  end

end

