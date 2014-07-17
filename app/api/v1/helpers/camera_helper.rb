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
    def hls_url_for_camera(camera)
	  auth = camera.config['auth']['basic']
	  rtsp_url = "rtsp://#{auth['username']}:#{auth['password']}@#{camera.config['external_host']}:#{camera.config['external_rtsp_port']}#{camera.rtsp_url}"
	  Evercam::Config[:hls][:base_path] + "/hls/m3u8_" + URI.escape(rtsp_url, ":/?.")
    end
   end
end
