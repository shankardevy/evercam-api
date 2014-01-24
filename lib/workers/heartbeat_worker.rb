require 'net/http'

module Evercam
  class HeartBeatWorker

    include Sidekiq::Worker
    sidekiq_options retry: false

    def perform(camera_name)
      camera = Camera[:exid => camera_name]
      updates = { is_online: false, polled_at: Time.now }

      camera.endpoints.each do |endpoint|
        begin
          next unless endpoint.public?
          uri = URI(endpoint.to_s)
          if Net::HTTP.get_response(uri).kind_of? Net::HTTPOK
            updates[:is_online] = true
            updates[:last_online_at] = Time.now
            break
          end
        rescue Exception
          # offline
        end
     end

      camera.update(updates)
    end

  end
end

