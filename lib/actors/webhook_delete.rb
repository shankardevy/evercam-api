module Evercam
  module Actors
    class WebhookDelete < Mutations::Command

      required do
        string :id
        integer :webhook_id
        integer :caller_id
      end

      def execute

        webhook = Webhook[webhook_id]
        
        if webhook.nil?
          raise Evercam::NotFoundError.new("Unable to locate the webhook with the id of '#{inputs[:webhook_id]}'.",
                                           "webhook_not_found_error", inputs[:webhook_id])
        end

        unless caller_id == webhook.user_id
          raise AuthorizationError.new("Unauthorized")
        end

        webhook.destroy 
      end
    end
  end
end
