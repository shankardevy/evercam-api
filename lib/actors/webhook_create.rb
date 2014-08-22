module Evercam
  module Actors
    class WebhookCreate < Mutations::Command

      required do
        string :id
        string :user_id
        string :url
        integer :caller_id
      end

      def validate
        unless URI.parse(url).kind_of?(URI::HTTP)
          raise Evercam::BadRequestError.new("Invalid URL specified.",
                                             "invalid_url",
                                             inputs[:url])
        end
      end

      def execute
        camera = Camera.by_exid(inputs[:id])
        if camera.nil?
          raise Evercam::NotFoundError.new("Unable to locate the '#{inputs[:id]}' camera.",
                                           "camera_not_found_error", inputs[:camera_id])
        end

        user = User.by_login(user_id)

        if user.nil?
          raise Evercam::NotFoundError.new("Unable to locate a user for '#{inputs[:user_id]}'.",
                                           "user_not_found_error", inputs[:user_id])
        end

        unless caller_id == User.by_login(user_id).id
          raise AuthorizationError.new("Unauthorized")
        end

        Webhook.create(camera: camera, user: user, url: url)
      end
    end
  end
end
