require 'net/http'

module Evercam
  class HeartBeatWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    TIMEOUT = 5

    def perform(camera_name)
      camera = Camera.by_exid(camera_name)
      updates = { is_online: false, polled_at: Time.now }

      camera.endpoints.each do |endpoint|
        next unless endpoint.public?
        con = Net::HTTP.new(endpoint.host, endpoint.port)

        begin
          con.open_timeout = TIMEOUT
          if con.get('/')
            updates.merge!(is_online: true, last_online_at: Time.now)
            break
          end
        rescue Net::OpenTimeout
          # offline
        rescue Exception => e
          # we weren't expecting this (famous last words)
          logger.warn(e)
        end

      end

      camera.update(updates)
    end

  end
end

