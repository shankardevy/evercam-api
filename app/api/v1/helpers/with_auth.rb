module Evercam
  class WithAuth

    def initialize(env)
      @env = env
      load_data
    end

    attr_reader :access_token, :user

    def demand(&block)
      authen_err unless @user
      block.call(@access_token, @user)
    end

    def allow?(&block)
      output = block.call(@access_token, @user)

      return output if output
      @access_token ? authoz_err : authen_err
    end

    def first_allowed(list)
      list.find {|entry| yield entry, @access_token, @user}
    end

    private

    def load_data
      case authen_type
        when :basic
          authen_with_http_basic
        when :bearer
          authen_with_access_token
        when :session
          authen_with_rack_session
        else
          nil
      end
    end

    def header
      @env['HTTP_AUTHORIZATION'] || ''
    end

    def session
      @env['rack.session'] || {}
    end

    def authen_type
      case header.split[0]
      when /basic/i then :basic
      when /bearer/i then :bearer
      else
        session[:user] ? :session : nil
      end
    end

    def authen_with_http_basic
      base64 = header.split[1]
      un, ps = Base64.decode64(base64).split(':')

      @user         = User.by_login(un) if un && ps
      @access_token = @user.token if @user && @user.password == ps 
      return @access_token if !@access_token.nil?
      authen_err 'Invalid or incorrect basic authentication'
    end

    def authen_with_rack_session
      @user         = User[session[:user]]
      @access_token = @user.token if !@user.nil?
      return @access_token if !@access_token.nil?
      authen_err 'Invalid or corrupt user session credentials'
    end

    def authen_with_access_token
      request       = header.split[1]
      @access_token = AccessToken.by_request(request)
      @user         = @access_token.user if !@access_token.nil?
      return @access_token if @access_token && @access_token.is_valid?
      authen_err 'Invalid or incorrect access token'
    end

    def authen_err(msg=nil)
      raise AuthenticationError,
        msg || 'Required authentication not supplied'
    end

    def authoz_err(msg=nil)
      raise AuthorizationError,
        msg || 'Required authorization not available'
    end

  end
end

