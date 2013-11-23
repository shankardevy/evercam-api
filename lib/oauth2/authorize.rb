module Evercam
  module OAuth2
    class Authorize

      def initialize(user, params)
        @u, @p = user, params
      end

      def valid?
        validate_client &&
          validate_redirect &&
          validate_type &&
          validate_scopes &&
          validate_user_can_authorize
      end

      def redirect?
        nil != redirect_to
      end

      def redirect_to
        return nil unless validate_redirect
        return redirect_uri unless fragment

        encoded = URI.encode_www_form(fragment)
        URI.join(redirect_uri, "##{encoded}").to_s
      end

      def error
        unless valid?
          fragment[:error_description]
        end
      end

      private

      def validate_client
        nil != client
      end

      def validate_redirect
        uri = @p[:redirect_uri]
        nil == uri || (client && client.allow_callback_uri?(uri))
      end

      def validate_type
        @p[:response_type] == 'token'
      end

      def validate_scopes
        false == scopes.empty? &&
          scopes.all? { |s| s.valid? }
      end

      def validate_user_can_authorize
        scopes.all? do |s|
          s.resource.has_right?('share', @u)
        end
      end

      def scopes
        names = @p[:scope] || ''
        names.split(/[\s,]+/).map do |s|
          AccessScope.new(s)
        end
      end

      def client
        Client.by_exid(@p[:client_id])
      end

      def redirect_uri
        @p[:redirect_uri] || client.default_callback_uri
      end

      def fragment
        if !validate_client
          {
            error: :invalid_request,
            error_description: 'the {client_id} param is missing or is invalid'
          }
        elsif !validate_redirect
          {
            error: :invalid_request,
            error_description: 'the {redirect_uri} param does not match any registered values'
          }
        elsif !validate_type
          {
            error: :unsupported_response_type,
            error_description: 'the {response_type} param is missing or is invalid'
          }
        elsif !validate_scopes
          {
            error: :invalid_scope,
            error_description: 'the {scope} param is missing or is invalid'
          }
        elsif !validate_user_can_authorize
          {
            error: :access_denied,
            error_description: 'the user cannot grant authorization to one or more scopes'
          }
        else
          nil
        end
      end

    end
  end
end
