require_relative './presenter'

module Evercam
  module Presenters
    class Model < Presenter
      root :models

      expose :id, documentation: {
        type: "string",
        desc: "Unique identifier of the model",
        required: true
      } do |m|
        m.exid
      end

      expose :name, documentation: {
        type: "string",
        desc: "Name of the model",
        required: true
      }

      expose :vendor_id, documentation: {
        type: "string",
        desc: "Unique identifier for the vendor",
        required: true
      } do |m, _o|
        m.vendor.exid
      end

      expose :default_username, documentation: {
        type: "string",
        desc: "Default username of the model",
        required: false
      }

      expose :default_password, documentation: {
        type: "string",
        desc: "Default password of the model",
        required: false
      }

      expose :jpg_url, documentation: {
        type: "string",
        desc: "Default Jpg image URL of the model",
        required: false
      }

      expose :h264_url, documentation: {
        type: "string",
        desc: "Default H264 stream URL of the model",
        required: false
      }

      expose :mjpg_url, documentation: {
        type: "string",
        desc: "Default Mjpeg stream URL of the model",
        required: false
      }

      expose :shape, documentation: {
        type: "string",
        desc: "Shape of the model",
        required: false
      }

      expose :resolution, documentation: {
        type: "string",
        desc: "Resolution(s) supported by model",
        required: false
      }

      expose :official_url, documentation: {
        type: "string",
        desc: "Official URL of the model",
        required: false
      }

      expose :audio_url, documentation: {
        type: "string",
        desc: "Audio stream URL of the model",
        required: false
      }

      expose :more_info, documentation: {
        type: "string",
        desc: "Additional information of the model",
        required: false
      }

      expose :poe, documentation: {
        type: "boolean",
        desc: "Whether or not POE is supported by the model",
        required: false
      }

      expose :wifi, documentation: {
        type: "boolean",
        desc: "Whether or not WiFi is supported by the model",
        required: false
      }

      expose :upnp, documentation: {
        type: "boolean",
        desc: "Whether or not UPNP is supported by the model",
        required: false
      }

      expose :ptz, documentation: {
        type: "boolean",
        desc: "Whether or not PTZ is supported by the model",
        required: false
      }

      expose :infrared, documentation: {
        type: "boolean",
        desc: "Whether or not Infrared is supported by the model",
        required: false
      }

      expose :varifocal, documentation: {
        type: "boolean",
        desc: "Whether or not Varifocal is supported by the model",
        required: false
      }

      expose :sd_card, documentation: {
        type: "boolean",
        desc: "Whether or not SD Card is supported by the model",
        required: false
      }

      expose :audio_io, documentation: {
        type: "boolean",
        desc: "Whether or not Audio Input/Output is supported by the model",
        required: false
      }

      expose :onvif, documentation: {
        type: "boolean",
        desc: "Whether or not OnVif is supported by the model",
        required: false
      }

      expose :psia, documentation: {
        type: "boolean",
        desc: "Whether or not PSIA is supported by the model",
        required: false
      }

      expose :discontinued, documentation: {
        type: "boolean",
        desc: "Whether or not the vendor has Discontinued this model",
        required: false
      }

      expose :icon_image, documentation: {
        type: "String",
        desc: "Model icon"
      } do |m, _o|
        "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/icon.jpg"
      end

      expose :thumbnail_image, documentation: {
        type: "String",
        desc: "Model thumbnail"
      } do |m, _o|
        "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/thumbnail.jpg"
      end

      expose :original_image, documentation: {
        type: "String",
        desc: "Model image"
      } do |m, _o|
        "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/original.jpg"
      end

      # temporary here, will be removed after alternate attributes 
      # will be used by other apps
      expose :defaults, documentation: {
        type: "hash",
        desc: "Various default values used by this camera model",
        required: true
      } do |m, _o|
        m.config
      end

      # temporary here, will be removed after alternate attributes 
      # will be used by other apps
      expose :images do
        expose :icon, documentation: {
          type: "String",
          desc: "Model icon"
        } do |m, _o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/icon.jpg"
        end

        expose :thumbnail, documentation: {
          type: "String",
          desc: "Model thumbnail"
        } do |m, _o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/thumbnail.jpg"
        end

        expose :original, documentation: {
          type: "String",
          desc: "Model Original"
        } do |m, _o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/original.jpg"
        end
      end
    end
  end
end
