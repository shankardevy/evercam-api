require_relative '../workers'

module Evercam
  module Actors
    class CameraUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :timezone
        string :name
        string :mac_address
        string :model
        string :vendor

        string :jpg_url
        string :external_url
        string :internal_url

        string :username
        array :endpoints, class: String, arrayize: true
        boolean :is_public

        hash :snapshots do
          string :jpg
        end

        hash :auth do
          hash :basic do
            string :username
            string :password
          end
        end

        string :cam_username
        string :cam_password
      end

      def validate
        if username && nil == User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exists')
        end

        if endpoints && endpoints.size == 0
          add_error(:endpoints, :size, 'Endpoints must contain at least one item')
        elsif endpoints
          endpoints.each do |e|
            unless e =~ URI.regexp
              add_error(:endpoints, :valid, 'One or more endpoints is not a valid URI')
            end
          end
        end

        if external_url && !(external_url =~ URI.regexp)
          add_error(:external_url, :valid, 'External url is invalid')
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
        camera = ::Camera.by_exid(inputs[:id])

        privacy_changed = false
        if !camera.is_public.nil?
          privacy_changed = (camera.is_public != is_public) if camera.is_public?
        end

        camera.name = name if name
        camera.owner = User.by_login(username) if username
        camera.is_public = is_public unless is_public.nil?

        if inputs[:snapshots]
          camera.values[:config]['snapshots'] = inputs[:snapshots]
          camera.values[:config]['snapshots'].each do |_, value|
            value.prepend('/') if value[0,1] != '/'
          end
        end

        camera.values[:config]['auth'] = inputs[:auth] if inputs[:auth]

        if inputs[:jpg_url]
          inputs[:jpg_url].prepend('/') if inputs[:jpg_url][0,1] != '/'
          camera.values[:config].merge!({'snapshots' => { 'jpg' => inputs[:jpg_url]}})
        end
        if inputs[:cam_username] or inputs[:cam_password]
          camera.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:cam_username], 'password' => inputs[:cam_password] }}})
        end

        camera.timezone = timezone if timezone
        camera.vendor_model =  VendorModel.find(:name => model, :vendor_id => Vendor.by_exid(vendor).first.id) if model
        camera.mac_address = mac_address if mac_address
        camera.save

        if privacy_changed
          # Camera made private so delete any public shares.
          CameraShare.where(kind: CameraShare::PUBLIC,
                            camera_id: camera.id).delete
        end

        if inputs[:endpoints]
          camera.remove_all_endpoints
          inputs[:endpoints].each do |e|
            add_endpoint(camera, e)
          end

          # fire off the evr.cm zone update to sidekiq
          primary = camera.endpoints.first
          DNSUpsertWorker.perform_async(id, primary.host)
        end

        if inputs[:external_url]
          add_endpoint(camera, inputs[:external_url])
        end

        if inputs[:internal_url]
          add_endpoint(camera, inputs[:internal_url])
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

