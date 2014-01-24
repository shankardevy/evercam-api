require 'sidekiq'

require_relative './config'
require_relative './models'

require_relative './workers/schedule_worker'
require_relative './workers/heartbeat_worker'
require_relative './workers/dns_upsert_worker'

