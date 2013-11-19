module Evercam
  module Withnail
    class WithAuth

      def initialize(env)
        @env = env
      end

      def has_right?(name, resource)
        resource.has_right?(name, client)
      end

      def client
        case auth_type
        when :basic
          authenticate_with_http_basic
        when :session
          authenticate_with_rack_session
        else
          raise AuthenticationError,
            'no Authentication mechanism was supplied'
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
        else
          session ? :session : nil
        end
      end

      def authenticate_with_http_basic
        base64 = header.split[1]
        un, ps = Base64.decode64(base64).split(':')

        user = User.by_login(un)
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

    end
  end
end

