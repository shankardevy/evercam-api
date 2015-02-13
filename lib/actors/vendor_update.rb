module Evercam
  module Actors
    class VendorUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :name
        array :known_macs
      end

      def validate

        if Vendor.by_exid(id).first.nil?
          add_error(:vendor, :exists, 'Vendor does not exist')
        end

        unless known_macs.blank?
          known_macs.each do |resource|
            if resource && resource != '' && !(resource =~ /^([0-9A-Fa-f]{2}[:-]){2}([0-9A-Fa-f]{2})$/)
              add_error(resource, :valid, 'Mac address is invalid')
            end
          end
        end

      end

      def execute
        vendor = ::Vendor.by_exid(inputs[:id]).first
        vendor.name = name if name
        vendor.known_macs.concat(known_macs).reject!(&:empty?)
        vendor.save

        vendor
      end
    end
  end
end