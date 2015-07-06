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
        model.jpg_url = jpg_url if jpg_url
        model.mjpg_url = mjpg_url if mjpg_url
        model.h264_url = h264_url if h264_url
        model.default_username = default_username if default_username
        model.default_password = default_password if default_password
        model.shape = shape if shape
        model.resolution = resolution if resolution
        model.official_url = official_url if official_url
        model.audio_url = audio_url if audio_url
        model.more_info = more_info if more_info
        model.poe = poe if poe
        model.wifi = wifi if wifi
        model.onvif = onvif if onvif
        model.psia = psia if psia
        model.ptz = ptz if ptz
        model.infrared = infrared if infrared
        model.sd_card = sd_card if sd_card
        model.varifocal = varifocal if varifocal
        model.upnp = upnp if upnp
        model.audio_io = audio_io if audio_io
        model.discontinued = discontinued if discontinued

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

        model.save
        model
      end
    end
  end
end
