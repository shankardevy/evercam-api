module Evercam
  module Actors
    class ShareDelete < Mutations::Command
      required do
        string :id
        string :user_id
      end

      optional do
        string :ip
      end

      def execute
        share = CameraShare.where(camera_id: inputs[:id], user_id: inputs[:user_id]).first
        if !share.nil?
          rights = AccessRightSet.for(share.camera, share.user)
          rights_list = []
          AccessRight::BASE_RIGHTS.each do |right|
            rights_list << right
            rights_list << "#{AccessRight::GRANT}~#{right}"
          end
          CameraShare.db.transaction do
            rights.revoke(*rights_list)
            share.delete
            CameraActivity.create(
              camera: share.camera,
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
