module Evercam
  module Actors
    class WebhookCreate < Mutations::Command

      required do
        string :camera_id
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
        camera = Camera.by_exid(inputs[:camera_id])
        if camera.nil?
          raise Evercam::NotFoundError.new("Unable to locate the '#{inputs[:camera_id]}' camera.",
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

        Webhook.create(camera: camera, user_id: user.id, url: url, exid: generate_webhook_id)
      end


      def generate_webhook_id
        loop do
          random_token = SecureRandom.hex(4)
          break random_token unless Webhook.find(exid: random_token)
        end
      end
    end
  end
end
