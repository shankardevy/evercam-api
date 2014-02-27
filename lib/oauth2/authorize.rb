module Evercam
  module OAuth2
    class Authorize

      Right = Struct.new(:right, :resource, :token)

      attr_reader :token

      def initialize(user, params)
        require 'pp'
        PP.pp params
        @user, @params = user, params
        @token = AccessToken.new(client: client,
                                 refresh: SecureRandom.base64(24))
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
        !redirect_to.nil?
      end

      def redirect_to
        return nil unless validate_client && validate_redirect
        return nil if valid? && !missing.empty? && @decline.nil?
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
        Client.by_exid(@params[:client_id])
      end

      def missing
        scopes.inject([]) do |list, scope|
          group, right, resource_id = scope.split(":")
          set = right_sets(client, scope).find do |rights|
            !rights.allow?(right)
          end
          list << Right.new(right, set.resource, @token) if !set.nil?
          list
        end
      end

      def approve!
        issue_access_token
      end

      def decline!
        @decline = true
      end

      private

      def scopes
        (@params[:scope] || '').split(/[\s,]+/)
      end

      def validate_client
        !client.nil?
      end

      def validate_redirect
        uri = @params[:redirect_uri]
        uri.nil? || (client && client.allow_callback_uri?(uri))
      end

      def validate_type
        @params[:response_type] == 'code'
      end

      def validate_scopes
        result = ![nil, ''].include?(@params[:scope])
        if result
          result = scopes.find do |scope|
            group, right, resource_id = scope.split(":")
            AccessRight.valid_right_name?(right)
          end
        end
        result
      end

      def validate_user_can_authorize
        scopes.find do |entry|
          group, right, resource_id = entry.split(":")
          right_sets(@user, entry).find do |rights|
            rights.allow?(right) == false
          end
        end.nil?
      end

      def right_sets(target, definition)
        resources = get_resources(definition, token.user)
        resources.nil? ? [] : resources.inject([]) {|list, resource| list << AccessRightSet.new(resource, target)}
      end

      def issue_access_token
        return nil unless valid?
        AccessToken.db.transaction do
          @token.save
          scopes.each do |entry|
            group, right, resource_id = entry.split(":")
            right_sets(client, entry).each do |rights|
              rights.grant(right)
            end
          end
        end
      end

      def redirect_uri
        @params[:redirect_uri] || client.default_callback_uri
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
            code: @token.refresh_code
          }
        else
          nil
        end
      end

      def get_resources(definition, user=nil)
        group, right, resource_id = definition.split(":")
        case group
          when 'cameras'
            @user.nil? ? [] : Camera.where(owner_id: @user.id)

          when 'camera'
            camera = Camera.where(exid: resource_id).first
            camera.nil? ? [] : [camera]
        end
      end

    end
  end
end

