module Evercam
  module Withnail
    class WithAuth

      def initialize(env)
        @env = env
      end

      def has_right?(name, resource)
        case auth_type
        when :basic
          user = User.by_login(basic[0])

          unless user && user.password == basic[1]
            raise AuthenticationError,
              'invalid username / email and password combination'
          end

          resource.has_right?(name, user)
        else
          raise AuthenticationError,
            'no Authorization header was supplied'
        end
      end

      private

      def header
        @env['HTTP_AUTHORIZATION'] || ''
      end

      def auth_type
        case header.split[0]
        when /basic/i then :basic
        else nil
        end
      end

      def basic
        base64 = header.split[1]
        Base64.decode64(base64).split(':')
      end

    end
  end
end

