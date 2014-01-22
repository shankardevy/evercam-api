require 'resolv'
require_relative '../dns'

module Evercam
  class DNSUpsertWorker

    include Sidekiq::Worker

    def perform(name, host)
      config = Evercam::Config[:amazon]
      manager = Evercam::DNS::ZoneManager.new('evr.cm', config)
      address = Resolv.getaddress(host)
      manager.update(name, address)
    end

  end
end

