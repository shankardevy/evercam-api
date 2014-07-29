require_relative './presenter'

module Evercam
  module Presenters
    class Camera < Presenter
      include CameraHelper

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

      expose :owned, if: lambda {|instance, options| !options[:user].nil? },
             documentation: {
               type: 'Boolean',
               desc: 'True if the user owns the camera, false otherwise'
             } do |c,o|
        (c.owner.id == o[:user].id)
      end

      expose :owner, documentation: {
        type: 'string',
        desc: 'Username of camera owner',
        required: true
      } do |s,o|
        s.owner.username
      end

      expose :vendor_id, documentation: {
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

      expose :discoverable, documentation: {
          type: 'boolean',
          desc: 'Whether the camera is publicly findable'
      } do |c,o|
        c.discoverable?
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
          { lat: c.location.y, lng: c.location.x }
        end
      end

      expose :external, if: lambda {|instance, options| !options[:minimal]} do

        expose :host, documentation: {
                   type: 'String',
                   desc: 'External host of the camera'
               } do |c,o|
          c.config['external_host']
        end

        expose :http do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'External http port of the camera'
                 } do |c,o|
            c.config['external_http_port'] unless c.config['external_http_port'].blank?
          end

          expose :camera, documentation: {
              type: 'String',
              desc: 'External camera url'
          } do |c,o|
            c.external_url
          end

          expose :jpg, documentation: {
              type: 'String',
              desc: 'External snapshot url'
          } do |c,o|
            host = c.external_url
            host << c.res_url('jpg') unless c.res_url('jpg').blank? or host.blank?
          end

          expose :mjpg, documentation: {
            type: 'String',
            desc: 'External mjpg url.'
          } do |c,o|
            host = c.external_url
            host << c.res_url('mjpg') unless c.res_url('mjpg').blank? or host.blank?
          end

        end

        expose :rtsp do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'External rtsp port of the camera'
                 } do |c,o|
            c.config['external_rtsp_port'] unless c.config['external_rtsp_port'].blank?
          end

          expose :mpeg, documentation: {
              type: 'String',
              desc: 'External mpeg url'
          } do |c,o|
            host = c.external_url('rtsp')
            host << c.res_url('mpeg') unless c.res_url('mpeg').blank? or host.blank?
          end

          expose :audio, documentation: {
              type: 'String',
              desc: 'External audio url'
          } do |c,o|
            host = c.external_url('rtsp')
            host << c.res_url('audio') unless c.res_url('audio').blank? or host.blank?
          end

          expose :h264, documentation: {
              type: 'String',
              desc: 'External h264 url'
          } do |c,o|
            host = c.external_url('rtsp')
            host << c.res_url('h264') unless c.res_url('h264').blank? or host.blank?
          end

        end
      end

      expose :internal, if: lambda {|instance, options| !options[:minimal]} do

        expose :host, documentation: {
                   type: 'String',
                   desc: 'Internal host of the camera'
               } do |c,o|
          c.config['internal_host']
        end

        expose :http do
          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'Internal http port of the camera'
                 } do |c,o|
            c.config['internal_http_port'] unless c.config['internal_http_port'].blank?
          end

          expose :camera, documentation: {
              type: 'String',
              desc: 'Internal camera url'
          } do |c,o|
            c.internal_url
          end

          expose :jpg, documentation: {
              type: 'String',
              desc: 'Internal snapshot url'
          } do |c,o|
            host = c.internal_url
            host << c.res_url('jpg') unless c.res_url('jpg').blank? or host.blank?
          end

          expose :mjpg, documentation: {
              type: 'String',
              desc: 'Mjpg url using evr.cm dynamic DNS'
          } do |c,o|
            host = c.internal_url
            host << c.res_url('mjpg') unless c.res_url('mjpg').blank? or host.blank?
          end

        end

        expose :rtsp do

          expose :port, documentation: {
                     type: 'Integer',
                     desc: 'Internal rtsp port of the camera'
                 } do |c,o|
            c.config['internal_rtsp_port'] unless c.config['internal_rtsp_port'].blank?
          end

          expose :mpeg, documentation: {
              type: 'String',
              desc: 'External mpeg url'
          } do |c,o|
            host = c.internal_url('rtsp')
            host << c.res_url('mpeg') unless c.res_url('mpeg').blank? or host.blank?
          end

          expose :audio, documentation: {
              type: 'String',
              desc: 'External audio url'
          } do |c,o|
            host = c.internal_url('rtsp')
            host << c.res_url('audio') unless c.res_url('audio').blank? or host.blank?
          end

          expose :h264, documentation: {
              type: 'String',
              desc: 'External h264 url'
          } do |c,o|
            host = c.internal_url('rtsp')
            host << c.res_url('h264') unless c.res_url('h264').blank? or host.blank?
          end

        end
      end

      expose :dyndns, if: lambda {|instance, options| !options[:minimal]} do

        expose :host, documentation: {
            type: 'String',
            desc: 'Internal host of the camera'
        } do |c,o|
          "http://#{c.exid}.evr.cm"
        end

        expose :http do

          expose :jpg, documentation: {
              type: 'String',
              desc: 'Snapshot url using evr.cm dynamic DNS'
          } do |c,o|
            host = c.dyndns_url
            host << c.res_url('jpg') unless c.res_url('jpg').blank? or host.blank?
          end

          expose :mjpg, documentation: {
              type: 'String',
              desc: 'Mjpg url using evr.cm dynamic DNS'
          } do |c,o|
            host = c.dyndns_url
            host << c.res_url('mjpg') unless c.res_url('mjpg').blank? or host.blank?
          end

        end

        expose :rtsp do

          expose :mpeg, documentation: {
              type: 'String',
              desc: 'Dynamis DNS mpeg url'
          } do |c,o|
            host = c.dyndns_url('rtsp')
            host << c.res_url('mpeg') unless c.res_url('mpeg').blank? or host.blank?
          end

          expose :audio, documentation: {
              type: 'String',
              desc: 'Dynamis DNS audio url'
          } do |c,o|
            host = c.dyndns_url('rtsp')
            host << c.res_url('audio') unless c.res_url('audio').blank? or host.blank?
          end

          expose :h264, documentation: {
              type: 'String',
              desc: 'Dynamis DNS h264 url'
          } do |c,o|
            host = c.dyndns_url('rtsp')
            host << c.res_url('h264') unless c.res_url('h264').blank? or host.blank?
          end

        end

      end

      expose :proxy_url do
        expose :jpg, documentation: {
          type: 'String',
          desc: 'Short snapshot url using evr.cm url shortener and proxy'
        } do |c,o|
          "http://evr.cm/#{c.exid}.jpg"
        end

        expose :hls, documentation: {
          type: 'String',
          desc: 'Hls url'
        } do |c,o|
          host = hls_url_for_camera(c)
          host unless host.blank?
        end

        expose :rtmp, documentation: {
          type: 'String',
          desc: 'RTMP url'
        } do |c,o|
          host = rtmp_url_for_camera(c)
          host unless host.blank?
        end

      end

      expose :rights, if: lambda {|instance, options| !options[:user].nil?},
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
        list.concat(grants) unless grants.empty?
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

