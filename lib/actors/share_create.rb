require_relative '../workers'

module Evercam
  module Actors
    class ShareCreate < Mutations::Command
    	required do
    		string :id
    		string :email
    		string :rights
    	end

    	optional do
    		string :message
    		boolean :notify
    	end

    	def validate
    		if Camera.where(exid: id).count == 0
    			add_error(:camera, :exists, "Camera does not exist")
    		end

    		if User.where(email: email).count == 0
    			add_error(:email, :exists, 'No user found for specified email address')
    		end

    		access_rights = to_rights_list(rights)
    		if rights.nil? || access_rights.size != rights.split(",").size
    			add_error(:rights, :valid, "Invalid rights specified in request")
    		end
    	end

    	def execute
    		user   = User.where(email: inputs[:email]).first
    		camera = Camera.by_exid(inputs[:id])

    		access_rights = AccessRightSet.new(camera, user)
    		kind          = (camera.is_public? ? CameraShare::PUBLIC : CameraShare::PRIVATE)
    		share         = nil
    		CameraShare.db.transaction do
    			rights_list = to_rights_list(inputs[:rights])
    			share       = CameraShare.create(camera: camera, user: camera.owner, sharer: user, kind: kind)
    			rights_list.delete_if {|r| AccessRight::PUBLIC_RIGHTS.include?(r)} if camera.is_public?
    			access_rights.grant(*rights_list) if rights_list.size > 0
    		end
    		share
    	end

    	private

    	def to_rights_list(names)
    		list = []
    		list = names.split(',').inject([]) do |list, name|
    			right_name = name.strip.downcase
    			list << right_name if AccessRight.valid_right_name?(right_name)
    			list
    		end if !names.nil?
    		list
    	end
    end
  end
end