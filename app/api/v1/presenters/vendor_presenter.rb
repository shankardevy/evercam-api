module Evercam
  class VendorPresenter

    def self.export(obj, opts={})
      {
        vendors: Array(obj).map do |vn|
          basic(vn).tap do |doc|
            doc.merge!(supported(vn)) if opts[:supported]
            doc.merge!(models(vn)) if opts[:models]
          end
        end
      }
    end

    def self.basic(vendor)
      {
        id: vendor.exid,
        name: vendor.name,
        known_macs: vendor.known_macs,
      }
    end

    def self.supported(vendor)
      {
        is_supported: !vendor.firmwares.empty?
      }
    end

    def self.models(vendor)
      {
        models: vendor.firmwares.map(&:known_models).flatten
      }
    end

  end
end

