module Evercam
   module AuthorizationHelper
   	def authorize!
   		requester = caller
   		raise AuthenticationError.new if requester.nil?
   	end

      # This method retrieves a model object representing the entity that is
      # making a request. This will either be a User or a Client. The method
      # can return nil if no authorization details are available.
   	def caller
   		token = access_token
   		token.nil? ? nil : token.target
   	end

      # Generates a right set for the requester on a specified resource.
   	def caller_rights_for(resource)
   		AccessRightSet.for(resource, caller)
   	end

      # This method fetches the access token associated with the request. This
      # will generally be determined from authorization details passed with the
      # request or previously established in the case of session based
      # authentication. The method can return nil if there is no authentication
      # data available.
   	def access_token
         log.debug "Fetching the access token for a request."
   		token  = nil
   		if request.headers.include?("Authorization")
            log.debug "Found an authorization header."
   			values    = request.headers["Authorization"].split
   			values[0] = values[0].downcase
            log.debug "Authorization header type: #{values[0]}"
   			if values[0] == "basic"
   				username, password = Base64.decode64(values[1]).split(":")
   				if username && password
                  log.debug "Fetching the user with the user name '#{username}'."
   				   user  = User.by_login(username)
   				   token = user.token if user && user.password == password
   				end
   			elsif values[0] == "bearer"
               log.debug "Fetching the access token for '#{values[1]}'."
   				token = AccessToken.where(request: values[1]).first
   			end
   		else
            log.debug "No authorization header found, checking for a session entry."
   			if session.include?(:user)
               log.debug "Session entry found, retrieving user id #{session[:user]}."
   				user  = User[session[:user]]
   				token = user.token if !user.nil?
   			end
   		end
   		token
   	end
   end
end