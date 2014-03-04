require_relative '../workers'

module Evercam
  module Actors
    class ShareDelete < Mutations::Command
    	required do
    		string :id
    		integer :share_id
    	end

    	def validate
    		if Camera.where(exid: id).count == 0
    			add_error(:camera, :exists, "Camera does not exist")
    		end
    	end

    	def execute
    		camera = Camera.by_exid(inputs[:id])
    		share  = CameraShare.where(id: inputs[:share_id]).first
            if !share.nil?
                rights = AccessRightSet.new(camera, share.sharer)
        		CameraShare.db.transaction do
                    rights.revoke(*AccessRight::BASE_RIGHTS)
                    share.delete
        		end
            end
    		true
    	end
    end
  end
end