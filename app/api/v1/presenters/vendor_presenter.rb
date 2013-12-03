module Evercam
  class VendorPresenter

    def self.export(obj, opts={})
      {
        vendors: Array(obj).map do |vn|
          basic(vn).tap do |doc|
            doc.merge!(firmwares(vn)) if opts[:firmwares]
          end
        end
      }
    end

    def self.basic(vendor)
      {
        id: vendor.exid,
        name: vendor.name,
        known_macs: vendor.known_macs
      }
    end

    def self.firmwares(vendor)
      {
        firmwares: vendor.firmwares.map do |fm|
          { name: fm.name }.merge(fm.config)
        end
      }
    end

  end
end

