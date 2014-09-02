module Evercam
  module Actors
    class WebhookUpdate < Mutations::Command

      required do
        string :id
        string :url
        integer :caller_id
      end

      def validate
        begin 
          webhook_url = URI.parse(url)
        rescue URI::InvalidURIError => err
          raise Evercam::BadRequestError.new("Invalid URL specified.",
                                               "invalid_url",
                                               inputs[:url])
        end
        unless webhook_url.kind_of?(URI::HTTP)
          raise Evercam::BadRequestError.new("Invalid URL specified.",
                                             "invalid_url",
                                             inputs[:url])
        end
      end

      def execute
        webhook = Webhook.where(exid: id).first
        
        if webhook.nil?
          raise Evercam::NotFoundError.new("Unable to locate the webhook with the id of '#{inputs[:id]}'.",
                                           "webhook_not_found_error", inputs[:id])
        end

        unless caller_id == webhook.user_id
          raise AuthorizationError.new("Unauthorized")
        end
        
        webhook.url = url
        webhook.save
      end
    end
  end
end
