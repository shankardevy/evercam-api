module Evercam
  module DNS
    class ZoneManager

      def initialize(root, config)
        @root, @config = root, config
      end

      def lookup(host)
        record = find(host)
        return nil unless record.exists?
        value(record)
      end

      def create(host, address)
        record = find(host)
        return nil if record.exists?

        zone.rrsets.create(fqdn(host), 'A', {
          ttl: 300, resource_records: [{ value: address }]
        })

        address
      end

      def delete(host)
        record = find(host)
        return nil unless record.exists?
        retval = value(record)
        record.delete
        retval
      end

      def update(host, address)
        delete(host)
        create(host, address)
      end

      private

      def route53
        @route53 ||= AWS::Route53.new(@config)
      end

      def zone
        @zone ||= (
          hosted_zone_id = @config[:route53][@root.to_sym]
          route53.hosted_zones[hosted_zone_id]
        )
      end

      def value(record)
        record.resource_records[0][:value]
      end

      def find(host)
        zone.rrsets[fqdn(host), 'A']
      end

      def fqdn(host)
        "#{host}.#{@root}."
      end

    end

  end
end

