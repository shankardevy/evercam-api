require 'sidekiq'
require 'sequel'
require 'net/http'

require_relative 'workers/heartbeat_worker'