module Evercam
   module ThreeScaleHelper
      @@client = ThreeScale::Client.new(provider_key: Evercam::Config[:threescale][:provider_key])

      # This method validates a requesters 3Scale credentials.
   	def authreport!(method_name='hits', usage_value=1)
   		settings = get_3scale_credentials.merge({method_name => usage_value})
         response = @@client.authrep(settings)

         puts response.error_message unless response.success? || Evercam::Config.env == :test
   	end

      # This method fetches the 3Scale API credentials for a request. It will
      # first check for these in the request parameters and, if they are not
      # found, then fall back on looking them up via other means.
   	def get_3scale_credentials
   		if !params.include?('app_id')
   			token = access_token
   			raise AuthenticationError.new("No access token found for request.") if token.nil?
   			entity = token.target
   			if entity.instance_of?(User)
   				{app_id: entity.api_id, app_key: entity.app_key}
   			else
   				{app_id: entity.exid, app_key: entity.secret}
   			end
   		else
   			{app_id: params['app_id'], app_key: params['app_key']}
   		end
   	end

   	# This method provides convenient access to the Rack session object.
      # Note that this method will ultimately be moved to the session helpers
      # when that becomes available and should be deleted from here once that
      # is the case.
   	def session
   		(env["rack.session"] || {})
   	end

      # This method fetches the access token associated with the request.
      # Note that this method will ultimately be moved to the authorization
      # helpers when that becomes available and should be deleted from here
      # once that is the case.
   	def access_token
   		token  = nil
   		if request.headers.include?("Authorization")
   			values    = request.headers["Authorization"].split
   			values[0] = values[0].downcase
   			if values[0] == "basic"
   				username, password = Base64.decode64(values[1]).split(":")
   				if username && password
   				   user  = User.by_login(username)
   				   token = user.token if user && user.password == password
   				end
   			elsif values[0] == "bearer"
   				token = AccessToken.where(request: values[1]).first
   			end
   		else
   			if session.include?(:user)
   				user  = User[session[:user]]
   				token = user.token if !user.nil?
   			end
   		end
   		token
   	end
   end
end