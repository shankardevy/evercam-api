# Copyright (c) 2014, Evercam.io

require 'aws-sdk'
require 'sidekiq'
require 'sidekiq/api'
require 'evercam_misc'
require 'dalli'

Sidekiq.configure_server do |c|
  c.redis = Evercam::Config[:sidekiq]
end

Sidekiq.configure_client do |c|
  c.redis = Evercam::Config[:sidekiq]
end

require_relative "zone_manager"
require_relative "workers/dns_upsert_worker"
require_relative "workers/heartbeat_worker"
require_relative "workers/intercom_events_worker"
require_relative "workers/cache_invalidation_worker"
require_relative "workers/email_worker"
require_relative "workers/ruby_worker"
