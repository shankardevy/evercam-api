require_relative '../workers'

module Evercam
  module Actors
    class CameraCreate < Mutations::Command

      required do
        string :id
        string :name
        string :username

        boolean :is_public
      end

      optional do
        string :timezone
        string :mac_address
        string :model
        string :vendor

        string :jpg_url
        string :external_url
        string :internal_url

        string :cam_username
        string :cam_password
      end

      def validate
        unless User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        unless id =~ /^[a-z0-9\-_]+$/
          add_error(:id, :valid, 'It can only contain lower case letters, numbers, hyphens and underscore')
        end

        if Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera already exists')
        end

        if external_url && !(external_url =~ URI.regexp)
          add_error(:external_url, :valid, 'External url is invalid')
        end

        if internal_url && !(internal_url =~ URI.regexp)
          add_error(:internal_url, :valid, 'Internal url is invalid')
        end

        if timezone && false == Timezone::Zone.names.include?(timezone)
          add_error(:timezone, :valid, 'Timezone does not exist or is invalid')
        end

        if vendor && !Vendor.by_exid(vendor)
          add_error(:username, :exists, 'Vendor does not exist')
        end

        if model && !vendor
          add_error(:model, :valid, 'If you provide model you must also provide vendor')
        end

        if model && vendor && !VendorModel.find(:name => model, :vendor_id => Vendor.by_exid(vendor).first.id)
          add_error(:model, :exists, 'Model does not exist')
        end
        
        if mac_address && !(mac_address =~ /^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$/)
          add_error(:mac_address, :valid, 'Mac address is invalid')
        end
      end

      def execute
        camera = Camera.new({
          exid: id,
          name: name,
          owner: User.by_login(username),
          is_public: is_public,
          config: {}
        })

        if inputs[:jpg_url]
          inputs[:jpg_url].prepend('/') if inputs[:jpg_url][0,1] != '/'
          camera.values[:config].merge!({'snapshots' => { 'jpg' => inputs[:jpg_url]}})
        end

        if inputs[:cam_username] or inputs[:cam_password]
          camera.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:cam_username], 'password' => inputs[:cam_password] }}})
        end

        camera.timezone = timezone if timezone
        camera.vendor_model = VendorModel.find(:name => model, :vendor_id => Vendor.by_exid(vendor).first.id) if model
        camera.mac_address = mac_address if mac_address
        camera.save

        CameraActivity.create(
          camera: camera,
          access_token: camera.owner.token,
          action: 'created',
          done_at: Time.now
        )

        if inputs[:external_url]
          add_endpoint(camera, inputs[:external_url])
        end

        if inputs[:internal_url]
          add_endpoint(camera, inputs[:internal_url])
        end

        if inputs[:external_url] or inputs[:internal_url]
          # fire off the evr.cm zone update to sidekiq
          primary = camera.endpoints.first
          DNSUpsertWorker.perform_async(id, primary.host)
        end

        camera
      end

      def add_endpoint(camera, url)
        endpoint = URI.parse(url)

        camera.add_endpoint({
          scheme: endpoint.scheme,
          host: endpoint.host,
          port: endpoint.port
        })
      end

    end
  end
end

