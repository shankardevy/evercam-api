require 'intercom'

Intercom.app_id = 'f9c1fd60de50d31bcbc3f4d8d74c9c6dbc40e95a'
Intercom.app_api_key  = 'e07f964835e66a91d356be0171895dea792c3c4b'

module Evercam
  class IntercomEventsWorker

    include Sidekiq::Worker

    def perform(event, email)
      begin
        Intercom::Event.create(
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

