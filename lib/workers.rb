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
  # Dalli cache
  options = { :namespace => "app_v1", :compress => true, :expires_in => 60*5 }
  if ENV["MEMCACHEDCLOUD_SERVERS"]
    Sidekiq::MEMCACHED = Dalli::Client.new(ENV["MEMCACHEDCLOUD_SERVERS"].split(','), :username => ENV["MEMCACHEDCLOUD_USERNAME"], :password => ENV["MEMCACHEDCLOUD_PASSWORD"])
  else
    Sidekiq::MEMCACHED = Dalli::Client.new('127.0.0.1:11211', options)
  end
end

require_relative "zone_manager"
require_relative "workers/dns_upsert_worker"
require_relative "workers/heartbeat_worker"
require_relative "workers/schedule_worker"
require_relative "workers/intercom_events_worker"
require_relative "workers/email_worker"
