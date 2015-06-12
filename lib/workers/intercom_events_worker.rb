require 'intercom'

module Evercam
  class IntercomEventsWorker

    include Sidekiq::Worker

    def perform(event, email)
      begin
        intercom = Intercom::Client.new(
          app_id: Evercam::Config[:intercom][:app_id],
          api_key: Evercam::Config[:intercom][:api_key]
        )
        intercom.events.create(
           :event_name => event,
           :created_at => Time.now.to_i,
           :email  => email
         )
        logger.info("Created #{event} event for #{email}")
      rescue => e
        logger.warn "Intercom exception: #{e.message}"
      end
    end

  end
end

