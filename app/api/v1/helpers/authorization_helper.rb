module Evercam
   module AuthorizationHelper
   	def authorize!
   		requester = caller
   		raise AuthenticationError.new("Unauthenticated") if requester.nil?
   	end

      # This method retrieves a model object representing the entity that is
      # making a request. This will either be a User or a Client. The method
      # can return nil if no authorization details are available.
   	def caller
   		token = access_token
   		token.nil? ? nil : token.target
   	end

      # Generates a right set for the requester on a specified resource.
   	def requester_rights_for(resource, scope=nil)
         if resource.instance_of?(User)
            raise "Invalid account scope specified." if !AccessRight::ALL_SCOPES.include?(scope)
            AccountRightSet.new(resource, caller, scope)
         else
   		   AccessRightSet.for(resource, caller)
         end
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
   			if values[0] == "bearer"
               log.debug "Fetching the access token for '#{values[1]}'."
   				token = AccessToken.where(request: values[1]).first
   			end
   		else
            parameters = request.params
            if parameters.include?(:api_id) && parameters.include?(:api_key)
               query = Client.where(exid: parameters[:api_id])
               if query.count == 0
                  user  = User.where(api_id: parameters[:api_id]).first
                  token = user.token if !user.nil?
               else
                  client = query.first
                  token  = AccessToken.where(client_id: client.id).order(Sequel.desc(:created_at)).first
               end
            end
   		end
   		token
   	end
   end
end