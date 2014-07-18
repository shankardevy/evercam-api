module Evercam
  module Actors
    class ShareCreate < ShareCreateCommon
      required do
        string :id
        string :email
        string :rights
      end

      optional do
        string :message
        boolean :notify
        string :grantor
      end

      def validate
        access_rights = to_rights_list(rights)
        if rights.nil? || access_rights.size != rights.split(",").size
          add_error(:rights, :valid, "Invalid rights specified in request")
        end
      end

      def execute
        camera = Camera.by_exid(inputs[:id])
        if camera.nil?
          raise Evercam::NotFoundError.new("Unable to locate the '#{inputs[:id]}' camera.",
                                           "camera_not_found_error", inputs[:id])
        end

        if inputs[:grantor] && User.where(username: grantor).count == 0
          raise Evercam::NotFoundError.new("Unable to locate a user for '#{inputs[:grantor]}'.",
                                           "share_grantor_not_found_error", inputs[:grantor])
        end

        user = User.where(email: inputs[:email].strip).first
        user = User.where(username: inputs[:email].strip).first if user.nil?

        if user.nil?
          if (/^.+@.+\..+$/ =~ inputs[:email].strip).nil?
            raise Evercam::BadRequestError.new("Invalid email address specified.",
                                               "invalid_share_email_address",
                                               inputs[:email])
          end
          create_share_for_email(inputs[:email])
        else
          create_share_for_user(user, camera)
        end
      end
    end
  end
end