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
        string :model, :empty => true
        string :vendor, :empty => true

        string :jpg_url
        string :external_host
        string :internal_host, :empty => true
        string :external_http_port, :empty => true
        string :internal_http_port, :empty => true
        string :external_rtsp_port, :empty => true
        string :internal_rtsp_port, :empty => true

        string :username
        boolean :is_public

        string :cam_username, :empty => true
        string :cam_password, :empty => true
      end

      def validate
        if username && nil == User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        unless Camera.by_exid(id)
          add_error(:camera, :exists, 'Camera does not exist')
        end

        if external_host && !external_host.empty? && !(external_host =~ ValidIpAddressRegex or external_host =~ ValidHostnameRegex)
          add_error(:external_host, :valid, 'External host is invalid')
        end

        if internal_host && !internal_host.empty? && !(internal_host =~ ValidIpAddressRegex or internal_host =~ ValidHostnameRegex)
          add_error(:internal_host, :valid, 'Internal host is invalid')
        end

        if timezone && false == Timezone::Zone.names.include?(timezone)
          add_error(:timezone, :valid, 'Timezone does not exist or is invalid')
        end

        if !vendor.empty? && Vendor.by_exid(vendor).first.nil?
          add_error(:vendor, :exists, 'Vendor does not exist')
        end

        if model && vendor.empty?
          add_error(:model, :valid, 'If you provide model you must also provide vendor')
        end

        if model && !vendor.empty? && !Vendor.by_exid(vendor).first.nil? && !VendorModel.find(:name => model, :vendor_id => Vendor.by_exid(vendor).first.id)
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

        if inputs[:jpg_url]
          inputs[:jpg_url].prepend('/') if inputs[:jpg_url][0,1] != '/'
          camera.values[:config].merge!({'snapshots' => { 'jpg' => inputs[:jpg_url]}})
        end

        if inputs[:cam_username] or inputs[:cam_password]
          camera.values[:config].merge!({'auth' => {'basic' => {'username' => inputs[:cam_username], 'password' => inputs[:cam_password] }}})
        end

        camera.timezone = timezone if timezone
        camera.vendor_model =  VendorModel.find(:name => model, :vendor_id => Vendor.by_exid(vendor).first.id) unless model.empty?
        camera.mac_address = mac_address if mac_address

        if privacy_changed
          # Camera made private so delete any public shares.
          CameraShare.where(kind: CameraShare::PUBLIC,
                            camera_id: camera.id).delete
        end

        camera.values[:config].merge!({'external_host' => inputs[:external_host]}) if inputs[:external_host]
        camera.values[:config].merge!({'external_http_port' => inputs[:external_http_port]}) if inputs[:external_http_port]
        camera.values[:config].merge!({'external_rtsp_port' => inputs[:external_rtsp_port]}) if inputs[:external_rtsp_port]

        camera.values[:config].merge!({'internal_host' => inputs[:internal_host]}) if inputs[:internal_host]
        camera.values[:config].merge!({'internal_http_port' => inputs[:internal_http_port]}) if inputs[:internal_http_port]
        camera.values[:config].merge!({'internal_rtsp_port' => inputs[:internal_rtsp_port]}) if inputs[:internal_rtsp_port]
        camera.save

        if inputs[:external_host]
          # fire off the evr.cm zone update to sidekiq
          #DNSUpsertWorker.perform_async(id, inputs[:external_host])
        end

        camera
      end

    end
  end
end

