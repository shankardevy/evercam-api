module Evercam
  module Actors
    class ModelCreate < Mutations::Command

      required do
        string :id
        string :name
        string :vendor_id
      end

      optional do
        string :jpg_url
        string :mjpg_url
        string :mpeg4_url
        string :mobile_url
        string :h264_url
        string :lowres_url
      end

      def validate
        unless id =~ /^[a-z0-9\-_]+$/ and id.length > 3
          add_error(:id, :valid, 'Model ID can only contain lower case letters, numbers, hyphens and underscore. Minimum length is 4.')
        end
      end

      def execute

        vendor = Vendor.where(exid: inputs[:vendor_id]).first
        raise NotFoundError.new("Unable to locate a vendor for '#{inputs[:vendor_id]}'.",
                                "vendor_not_found_error", inputs[:vendor_id]) if vendor.blank?
        model = VendorModel.new(
            exid: id,
            name: name,
            vendor: vendor,
            config: {}
        )
        [:jpg, :mjpg, :mpeg4, :mobile, :h264, :lowres].each do |resource|
          url_name = "#{resource}_url"
          unless inputs[url_name].blank?
            inputs[url_name].prepend('/') if inputs[url_name][0,1] != '/'
            if model.values[:config].has_key?('snapshots')
              model.values[:config]['snapshots'].merge!({resource => inputs[url_name]})
            else
              model.values[:config].merge!({'snapshots' => { resource => inputs[url_name]}})
            end
          end
        end
        VendorModel.db.transaction do
          model.save
        end
      end
    end
  end
end