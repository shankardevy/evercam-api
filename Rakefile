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

    task :up do
      db = Sequel.connect(Evercam::Config[:database])
      Sequel::Migrator.run(db, 'migrations')
    end

  end

end

