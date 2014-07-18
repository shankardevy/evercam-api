module Evercam
  module Actors
    class ShareDelete < Mutations::Command
    	required do
    		string :id
    		integer :share_id
      end

      optional do
        string :ip
      end

    	def validate
    		if Camera.where(exid: id).count == 0
    			add_error(:camera, :exists, "Camera share does not exist")
    		end
    	end

    	def execute
    		camera = Camera.by_exid(inputs[:id])
    		share  = CameraShare.where(id: inputs[:share_id]).first
         if !share.nil?
            rights      = AccessRightSet.for(camera, share.user)
            rights_list = []
            AccessRight::BASE_RIGHTS.each do |right|
               rights_list << right
               rights_list << "#{AccessRight::GRANT}~#{right}"
            end
            CameraShare.db.transaction do
               rights.revoke(*rights_list)
               share.delete
               CameraActivity.create(
                 camera: camera,
                 access_token: share.sharer.token,
                 action: 'stopped sharing',
                 done_at: Time.now,
                 ip: inputs[:ip],
                 extra: {:with => share.user.email}
               )
            end
         end
    		true
    	end
    end
  end
end