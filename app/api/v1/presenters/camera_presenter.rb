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

      expose :owner, documentation: {
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

      expose :vendor_name, documentation: {
        type: 'string',
        desc: 'The name for the camera vendor'
      } do |c,o|
        nil == c.vendor ? nil : c.vendor.name
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
        desc: 'Name of the <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">IANA/tz</a> timezone where this camera is located',
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
        c.config['external_http_port'] unless c.config['external_http_port'].blank?
      end

      expose :internal_http_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'Internal http port of the camera'
      } do |c,o|
        c.config['internal_http_port'] unless c.config['internal_http_port'].blank?
      end

      expose :external_rtsp_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'External rtsp port of the camera'
      } do |c,o|
        c.config['external_rtsp_port'] unless c.config['external_rtsp_port'].blank?
      end

      expose :internal_rtsp_port, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'Integer',
        desc: 'Internal rtsp port of the camera'
       } do |c,o|
        c.config['internal_rtsp_port'] unless c.config['internal_rtsp_port'].blank?
      end

      expose :jpg_url, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'Snapshot url'
      } do |c,o|
        c.jpg_url
      end

      expose :rtsp_url, if: lambda {|instance, options| !options[:minimal]},
             documentation: {
        type: 'String',
        desc: 'RTSP url'
      } do |c,o|
        c.rtsp_url
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

      expose :location_lng, documentation: {
        type: 'float',
        desc: 'GPS longitude coordinate of the camera'
      } do |c,o|
        c.location.x if c.location
      end

      expose :location_lat, documentation: {
        type: 'float',
        desc: 'GPS latitude coordinate of the camera'
      } do |c,o|
        c.location.y if c.location
      end

      expose :discoverable, documentation: {
        type: 'boolean',
        desc: 'Whether the camera is publicly findable'
      } do |c,o|
         c.discoverable?
      end

      expose :external, if: lambda {|instance, options| !options[:minimal]} do

        expose :jpg_url, documentation: {
                 type: 'String',
                 desc: 'External snapshot url'
               } do |c,o|
          host = c.external_url
          host << c.jpg_url unless c.jpg_url.blank? or host.blank?
        end

        expose :rtsp_url, documentation: {
          type: 'String',
          desc: 'External RTSP url'
        } do |c,o|
          host = c.external_url(port_type='rtsp')
          host << c.rtsp_url unless c.rtsp_url.blank? or host.blank?
        end

      end

      expose :internal, if: lambda {|instance, options| !options[:minimal]} do

        expose :jpg_url, documentation: {
                 type: 'String',
                 desc: 'Internal snapshot url'
               } do |c,o|
          host = c.internal_url
          host << c.jpg_url unless c.jpg_url.blank? or host.blank?
        end
        expose :rtsp_url, documentation: {
          type: 'String',
          desc: 'Internal RTSP url'
        } do |c,o|
          host = c.internal_url(port_type='rtsp')
          host << c.rtsp_url unless c.rtsp_url.blank? or host.blank?
        end
      end

      expose :dyndns, if: lambda {|instance, options| !options[:minimal]} do
        expose :jpg_url, documentation: {
          type: 'String',
          desc: 'Snapshot url using evr.cm dynamic DNS'
        } do |c,o|
          port = c.config.fetch('external_http_port', nil)
          host = "http://#{c.exid}.evr.cm"
          host << ":#{port}" unless port.blank? or port == 80
          host << c.jpg_url unless c.jpg_url.blank? or host.blank?
        end

        expose :rtsp_url, documentation: {
          type: 'String',
          desc: 'RTSP url using evr.cm dynamic DNS'
        } do |c,o|
          port = c.config.fetch('external_rtsp_port', nil)
          host = "rtsp://#{c.exid}.evr.cm"
          host << ":#{port}" unless port.blank? or port == 80
          host << c.rtsp_url unless c.rtsp_url.blank? or host.blank?
        end

      end

      expose :short do
        expose :jpg_url, documentation: {
          type: 'String',
          desc: 'Short snapshot url using evr.cm url shortener'
        } do |c,o|
          "http://evr.cm/#{c.exid}.jpg"
        end
      end

      expose :owned, if: lambda {|instance, options| options.include?(:user)},
                     documentation: {
                       type: 'Boolean',
                       desc: 'True if the user owns the camera, false otherwise'
                     } do |c,o|
        (c.owner.id == o[:user].id)
      end

      expose :rights, if: lambda {|instance, options| options.include?(:user)},
                      documentation: {
                        type: 'String',
                        desc: 'A comma separated list of the users rights on the camera'
                      } do |camera, options|
        list   = []
        grants = []
        rights = AccessRightSet.for(camera, options[:user])
        AccessRight::BASE_RIGHTS.each do |right|
          list << right if rights.allow?(right)
          grants << "#{AccessRight::GRANT}~#{right}" if rights.allow?("#{AccessRight::GRANT}~#{right}")
        end
        list.concat(grants) if !grants.empty?
        list.join(",")
      end

      expose :thumbnail, if: lambda {|instance, options| options[:thumbnail]},
             documentation: {
               type: 'Image',
               desc: '150x150 preview of camera view'
             } do |c,o|
        data = Base64.encode64(c.preview).gsub("\n", '') unless c.preview.nil?
        c.preview.nil? ? nil : "data:image/jpeg;base64,#{data}"
      end

    end
  end
end

