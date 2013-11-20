module Evercam
  module Withnail
    class WithAuth

      def initialize(env)
        @env = env
      end

      def has_right?(right, resource)
        resource.has_right?(right, seeker)
      end

      def seeker
        case auth_type
        when :basic
          authenticate_with_http_basic
        when :token
          authenticate_with_access_token
        when :session
          authenticate_with_rack_session
        else
          raise AuthenticationError,
            'no supported authentication was supplied'
        end
      end

      private

      def header
        @env['HTTP_AUTHORIZATION'] || ''
      end

      def session
        @env['rack.session']
      end

      def auth_type
        case header.split[0]
        when /basic/i then :basic
        when /bearer/i then :token
        else
          session ? :session : nil
        end
      end

      def authenticate_with_http_basic
        base64 = header.split[1]
        un, ps = Base64.decode64(base64).split(':')

        user = User.by_login(un) if un && ps
        return user if user && user.password == ps

        raise AuthenticationError,
          'invalid username / email and password combination'
      end

      def authenticate_with_rack_session
        user = User[session[:user]]
        return user if user

        raise AuthenticationError,
          'invalid or corrupt user session'
      end

      def authenticate_with_access_token
        request = header.split[1]
        token = AccessToken.by_request(request)
        return token if token && token.is_valid?

        raise AuthenticationError,
          'unknown or invalid access token'
      end

    end
  end
end

