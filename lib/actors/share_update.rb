module Evercam
  module Actors
    class ShareUpdate < ShareCreateCommon
      required do
        string :id
        string :user_id
        string :rights
      end

      optional do
        string :ip
      end

      def validate
        access_rights = to_rights_list(rights)
        if rights.nil? || access_rights.size != rights.split(",").size
          add_error(:rights, :valid, "Invalid rights specified in request")
        end
      end

      def execute
        share = CameraShare.where(camera_id: inputs[:id], user_id: inputs[:user_id]).first
        rights_list = to_rights_list(inputs[:rights])
        rights = AccessRightSet.for(share.camera, share.user)

        CameraRightSet::VALID_RIGHTS.each do |right|
          if rights_list.include?(right)
            rights.grant(right) if !rights.allow?(right)
          else
            rights.revoke(right) if rights.allow?(right)
          end
        end
        CameraActivity.create(
          camera: share.camera,
          access_token: share.sharer.token,
          action: 'updated share',
          done_at: Time.now,
          ip: inputs[:ip],
          extra: {:with => share.user.email}
        )
        share
      end
    end
  end
end
