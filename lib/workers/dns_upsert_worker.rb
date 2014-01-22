require_relative '../dns'

module Evercam
  class DNSUpsertWorker

    include Sidekiq::Worker

    def perform(name, address)
      config = Evercam::Config[:amazon]
      manager = Evercam::DNS::ZoneManager.new('evr.cm', config)
      manager.update(name, address)
    end

  end
end

