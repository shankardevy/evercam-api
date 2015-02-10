module Evercam
  module Actors
    class VendorCreate < Mutations::Command

      required do
        string :id
        string :name
      end

      optional do
        array :known_macs
      end

      def validate
        unless id =~ /^[a-z0-9\-_]+$/ and id.length > 3
          add_error(:id, :valid, 'Vendor ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.')
        end

        unless known_macs.blank?
          known_macs.each do |resource|
            if resource && !(resource =~ /^([0-9A-Fa-f]{2}[:-]){2}([0-9A-Fa-f]{2})$/)
              add_error(resource, :valid, 'Mac address is invalid')
            end
          end
        end

      end

      def execute

        vendor = Vendor.new(
                  exid: id,
                  name: name,
                  known_macs: known_macs
                )
        Vendor.db.transaction do
          vendor.save
        end
      end
    end
  end
end