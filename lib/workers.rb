require 'sidekiq'

require_relative './config'
require_relative './workers/dns_upsert_worker'

