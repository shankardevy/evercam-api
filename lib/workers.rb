require 'sidekiq'

require_relative './config'
require_relative './models'

Sidekiq.configure_server do |c|
  c.redis = Evercam::Config[:sidekiq]
end

Sidekiq.configure_client do |c|
  c.redis = Evercam::Config[:sidekiq]
end

require_relative './workers/schedule_worker'
require_relative './workers/heartbeat_worker'
require_relative './workers/dns_upsert_worker'

