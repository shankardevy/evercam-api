module Evercam
  module OAuth2
    class Authorize

      def initialize(params)
        @params = params
      end

      def valid?
        validate_response_type &&
          validate_client_exists &&
          validate_redirect_uri
      end

      def redirect?
        validate_redirect_uri
      end

      def uri
        return nil unless validate_redirect_uri
        uri = @params[:redirect_uri] || client.default_callback_uri
        URI.join(uri, '#error=unsupported_response_type').to_s
      end

      def client
        @client ||= Client.by_exid(@params[:client_id])
      end

      def error
        if !validate_client_exists
          'the {client_id} paramater is either missing or invalid'
        elsif !validate_redirect_uri
          'the {redirect_uri} parameter does not match any registered options'
        end
      end

      private

      def validate_response_type
        ['token'].include?(@params[:response_type])
      end

      def validate_client_exists
        nil != client
      end

      def validate_redirect_uri
        return false unless client
        uri = @params[:redirect_uri]
        nil == uri || client.allow_callback_uri?(uri)
      end

    end
  end
end

