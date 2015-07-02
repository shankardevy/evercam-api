module Evercam
  module Actors
    class ModelUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :name
        string :jpg_url, empty: true
        string :mjpg_url, empty: true
        string :mpeg4_url, empty: true
        string :mobile_url, empty: true
        string :h264_url, empty: true
        string :lowres_url, empty: true
        string :default_username, empty: true
        string :default_password, empty: true
        string :shape, empty: true
        string :resolution, empty: true
        string :official_url, empty: true
        string :audio_url, empty: true
        string :more_info, empty: true
        string :poe, empty: true
        string :wifi, empty: true
        string :onvif, empty: true
        string :psia, empty: true
        string :ptz, empty: true
        string :infrared, empty: true
        string :varifocal, empty: true
        string :sd_card, empty: true
        string :upnp, empty: true
        string :audio_io, empty: true
        string :discontinued, empty: true
      end

      def validate
        if VendorModel.where(exid: id).first.nil?
          add_error(:model, :exists, "Model does not exist")
        end
      end

      def execute
        model = ::VendorModel.where(exid: inputs[:id]).first

        model.name = name if name
        [:jpg, :mjpg, :mpeg4, :mobile, :h264, :lowres].each do |resource|
          url_name = "#{resource}_url"
          unless inputs[url_name].blank?
            if model.values[:config].has_key?('snapshots')
              model.values[:config]['snapshots'].merge!({resource => inputs[url_name]})
            else
              model.values[:config].merge!({'snapshots' => { resource => inputs[url_name]}})
            end
          end
        end

        if inputs[:default_username] or inputs[:default_password]
          model.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:default_username].to_s.empty? ? '' : inputs[:default_username],
                                                                'password' => inputs[:default_password].to_s.empty? ? '' : inputs[:default_password]}}})
        end

        [:shape, :resolution, :official_url, :audio_url, :more_info, :poe, :wifi, :onvif, :psia, :ptz, :infrared, :varifocal, :sd_card, :upnp, :audio_io, :discontinued].each do |spec|
          unless inputs[spec].blank?
            if model.values[:specs].has_key?(spec)
              model.values[:specs][spec] = inputs[spec]
            else
              model.values[:specs].merge!(spec => inputs[spec])
            end
          end
        end

        model.save
        model
      end
    end
  end
end