module Evercam
  module Actors
    class ShareCreateCommon < Mutations::Command

      protected

      def to_rights_list(names)
         list = []
         list = names.split(',').inject([]) do |list, name|
            right_name = name.strip.downcase
            list << right_name if AccessRight.valid_right_name?(right_name)
            list
         end if !names.nil?
         list
      end

      def create_share_for_user(user, camera)
         grantor = (inputs[:grantor] ? User.where(username: inputs[:grantor]).first : camera.owner)
         create_share(grantor, user, camera, inputs[:rights])
      end

      def create_share_for_request(share_request)
         user = User.where(email: share_request.email).first
         Sequel::Model.db.transaction do
            share_request.update(status: CameraShareRequest::USED)
            create_share(share_request.user, user, share_request.camera, share_request.rights)
         end
      end

      def create_share_for_email(email)
         camera = Camera.by_exid(inputs[:id])
         if CameraShareRequest.where(camera: camera,
                                     status: CameraShareRequest::PENDING,
                                     email: email).count != 0
            raise Evercam::ConflictError.new("A share request already exists for the '#{email}' email address for this camera.",
                                             "duplicate_share_request_error", email)
         end

         grantor = (inputs[:grantor] ? User.where(username: inputs[:grantor]).first : camera.owner)
         CameraShareRequest.create(camera: camera,
                                   user:   grantor,
                                   status: CameraShareRequest::PENDING,
                                   email:  email,
                                   rights: inputs[:rights])
      end

      private

      def create_share(sharer, sharee, camera, rights)
         if CameraShare.where(camera: camera, user: sharee).count != 0
            raise Evercam::ConflictError.new("The camera has already been shared with this user.",
                                             "duplicate_share_error", sharee.username, sharee.email)
         end

         access_rights = AccessRightSet.for(camera, sharee)
         rights_list   = to_rights_list(rights)
         rights_list.delete_if {|r| CameraRightSet::PUBLIC_RIGHTS.include?(r)} if camera.is_public?
         share         = nil
         Sequel::Model.db.transaction do
            share = CameraShare.create(camera: camera, user: sharee, sharer: sharer, kind: CameraShare::PRIVATE)
            access_rights.grant(*rights_list) if rights_list.size > 0
         end
         share
      end
    end
  end
end