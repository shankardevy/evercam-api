module Evercam
  module Actors
    class ShareCreateForRequest < ShareCreateCommon
      required do
         string :key
         string :email
      end

      def validate
         share_request = CameraShareRequest.where(status: CameraShareRequest::PENDING,
                                                  key: key).first
         if share_request.nil?
            add_error(:camera_share_request, :exists, "Camera share request does not exist")
         end

         if share_request && share_request.email != email
            add_error(:email, :invalid, "The email address specified does not match the share request email")
         end
      end

      def execute
         create_share_for_request(CameraShareRequest.where(key: inputs[:key]).first)
      end
    end
  end
end