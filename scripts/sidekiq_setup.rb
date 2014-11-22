require 'dotenv'
require 'sequel'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

require 'evercam_misc'
require 'evercam_models'
require_relative '../lib/workers'
require_relative '../app/api/v1/helpers/cache_helper'
