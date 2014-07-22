require 'resolv'

module Evercam
  class DNSUpsertWorker

    include Sidekiq::Worker

    def perform(name, host)
      config = Evercam::Config[:amazon]
      manager = Evercam::DNS::ZoneManager.new('evr.cm', config)

      address = Resolv.getaddresses(host).find do |a|
        Resolv::IPv4::Regex =~ a
      end

      manager.update(name, address)
    end

  end
end

