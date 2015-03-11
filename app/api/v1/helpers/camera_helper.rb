module Evercam
  module CameraHelper
    # This method searches the list of cameras owned by a user to find a match
    # based on the cameras MAC address. If a match is not found then the
    # method next searches the list of cameras shared with the user. Finally,
    # if no match is found, the method returns nil.
    def camera_for_mac(user, mac_address)
      camera = Camera.where(mac_address: mac_address, owner: user).first
      if camera.nil?
        camera = CameraShare.join(:cameras,
                                  :camera_id).where(camera_shares__sharer_id: user.id,
                                                    cameras__mac_address: mac_address).first
      end
      camera
    end

    def get_cam(exid)
      camera = Evercam::Services::dalli_cache.get(exid)
      if camera.nil?
        camera = Camera.by_exid!(exid)
        Evercam::Services::dalli_cache.set(exid, camera, 0)
      end
      camera
    end


    def rtsp_url_for_camera(camera)
      port = camera.config['external_rtsp_port']
      port = "554" if port == ""
      port = ":" + port.to_s
      h264_url = camera.res_url('h264')
      ext_url = camera.config['external_host']
      unless h264_url.blank? or ext_url.blank?
        "rtsp://#{camera.cam_username}:#{camera.cam_password}@#{ext_url}#{port}#{h264_url}"
      else
        nil
      end
    end
    
    def hls_url_for_camera(camera)
      rtsp_url = rtsp_url_for_camera(camera)
      Evercam::Config[:streams][:hls_path] + "/live/" + CGI.escape(rtsp_url) unless rtsp_url.nil?
    end

    def rtmp_url_for_camera(camera)
      rtsp_url = rtsp_url_for_camera(camera)
      Evercam::Config[:streams][:rtmp_path] + "/live/" + CGI.escape(rtsp_url) unless rtsp_url.nil?
    end

    def auto_generate_camera_id(camera_name)
      camera_name = camera_name.downcase.gsub(' ','')
      chars = [('a'..'z'), (0..9)].flat_map { |i| i.to_a }
      random_string = (0...3).map { chars[rand(chars.length)] }.join
      "#{camera_name[0..5]}-#{random_string}"
    end
  end
end
