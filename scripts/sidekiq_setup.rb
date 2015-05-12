require 'dotenv'
require 'sequel'
require 'pusher'

Dotenv.load
Sequel::Model.db = Sequel.connect("#{ENV['DATABASE_URL']}", max_connections: 25)

Pusher.app_id = ENV['PUSHER_APP']
Pusher.key = ENV['PUSHER_KEY']
Pusher.secret = ENV['PUSHER_SECRET']
Pusher.encrypted = true

require 'evercam_misc'
require 'evercam_models'
require_relative '../lib/workers'
