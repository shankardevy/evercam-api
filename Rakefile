require 'rake'
require 'rspec'

if defined?(RSpec)
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
end

namespace :schema do

  require_relative './lib/models'
  db = Sequel::Model.db

  task :version do
    version = db[:_schema].where(key: 'VERSION').get(:value)
    puts %(CURRENT #{version})
  end

  task :migrate do
    repo = db[:_schema].where(key: 'VERSION')
    base = File.expand_path('../migrations/*', __FILE__)

    # grab the current schema version, rescue to zero
    current_version = repo.get(:value) rescue ('0' * 4)
    puts %(START #{current_version})

    # cycle over each of the migration scripts
    Dir.glob(base).sort.each do |path|
      next unless File.directory?(path)

      # pull out the timestamp and check against schema
      migration_version = File.basename(path).split('.')[0]
      next unless migration_version > current_version
      puts %(APPLY #{migration_version})

      # perform correct action for file-type
      Dir.glob(File.join(path, '*')).each do |file|
        case File.extname(file)
        when '.sql' then db.run File.read(file)
        when '.rb' then `#{file}`
        else raise ArgumentError, "unknown file-type #{file}"
        end
      end

      repo.update(value: migration_version) rescue nil
      current_version = migration_version
    end

    puts %(FINAL #{current_version})
  end

end

