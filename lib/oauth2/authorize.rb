module Evercam
  module OAuth2
    class Authorize

      attr_reader :token

      def initialize(user, params)
        @u, @p = user, params
        issue_access_token if valid? && missing.empty?
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
        return nil unless validate_client && validate_redirect
        return nil if valid? && false == missing.empty? && @decline.nil?
        return redirect_uri unless fragment

        encoded = URI.encode_www_form(fragment)
        URI.join(redirect_uri, "##{encoded}").to_s
      end

      def error
        unless valid? && nil == @decline
          fragment[:error_description]
        end
      end

      def client
        Client.by_exid(@p[:client_id])
      end

      def missing
        scopes.select do |s|
          false == client.tokens.any? do |t|
            t.grantor == @u && t.allow?(s.to_s)
          end
        end
      end

      def approve!
        issue_access_token
      end

      def decline!
        @decline = true
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
          s.generic? || s.resource.owner == @u
        end
      end

      def scopes
        names = @p[:scope] || ''
        names.split(/[\s,]+/).map do |s|
          AccessScope.new(s)
        end
      end

      def issue_access_token
        return nil unless valid?
        @token = AccessToken.create(grantor: @u, grantee: client).tap do |t|
          scopes.each do |s|
            t.add_right(name: s.to_s)
          end
        end
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
        elsif @decline
          {
            error: :access_denied,
            error_description: 'the resource owner denied the authorization requested'
          }
        elsif @token
          {
            access_token: @token.request,
            expires_in: @token.expires_in,
            token_type: :bearer
          }
        else
          nil
        end
      end

    end
  end
end

