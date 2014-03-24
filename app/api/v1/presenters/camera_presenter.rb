require_relative './presenter'

module Evercam
  module Presenters
    class Camera < Presenter

      root :cameras

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique Evercam identifier for the camera',
        required: true
      } do |s,o|
        s.exid
      end

      expose :name, documentation: {
        type: 'string',
        desc: 'Human readable or friendly name for the camera',
        required: true
      }

      expose :owner, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'string',
        desc: 'Username of camera owner',
        required: true
      } do |s,o|
        s.owner.username
      end

      expose :vendor, documentation: {
        type: 'string',
        desc: 'Unique identifier for the camera vendor'
      } do |c,o|
        nil == c.vendor_model ? nil : c.vendor_model.vendor.exid
      end

      expose :model, documentation: {
        type: 'string',
        desc: 'Name of the camera model'
      } do |c,o|
        nil == c.vendor_model ? nil : c.vendor_model.name
      end

      with_options(format_with: :timestamp) do

        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation',
          required: true
        }

        expose :updated_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last update',
          required: true
        }

        expose :last_polled_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last heartbeat poll'
        }

        expose :last_online_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp of the last successful heartbeat of the camera'
        }

      end

      expose :timezone, documentation: {
        type: 'string',
        desc: 'Name of the IANA/tz timezone where this camera is located',
        required: true
      } do |s,o|
        s.timezone.zone
      end

      expose :is_online, documentation: {
        type: 'boolean',
        desc: 'Whether or not this camera is currently online'
      }

      expose :is_public, documentation: {
        type: 'boolean',
        desc: 'Whether or not this camera is publically available',
        required: true
      }

      expose :external_host, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'External host of the camera'
      } do |c,o|
        c.config['external_host']
      end

      expose :internal_host, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'Internal host of the camera'
      } do |c,o|
        c.config['internal_host']
      end

      expose :external_http_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'External http port of the camera'
      } do |c,o|
        c.config['external_http_port']
      end

      expose :internal_http_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'Internal http port of the camera'
      } do |c,o|
        c.config['internal_http_port']
      end

      expose :external_rtsp_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'Internal rtsp port of the camera'
      } do |c,o|
        c.config['external_rtsp_port']
      end

      expose :internal_rtsp_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'External rtsp port of the camera'
       } do |c,o|
        c.config['internal_rtsp_port']
      end

      expose :jpg_url, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'Snapshot url'
      } do |c,o|
        c.jpg_url
      end

      expose :cam_username, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'Camera username'
      } do |c,o|
        c.cam_username
      end

      expose :cam_password, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'Camera password'
      } do |c,o|
        c.cam_password
      end

      expose :mac_address, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'string',
        desc: 'The physical network MAC address of the camera'
      }

      expose :location, documentation: {
        type: 'hash',
        desc: 'GPS lng and lat coordinates of the camera location'
      } do |c,o|
        if c.location
          { lng: c.location.x, lat: c.location.y }
        end
      end

    end
  end
end

