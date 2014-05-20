require 'dotenv'
require 'sequel'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

require 'evercam_misc'
require 'evercam_models'
require 'evercam_sidekiq'
require 'evercam_actors'
