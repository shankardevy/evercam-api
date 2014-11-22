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
      caller = nil
      token = access_token
      if token.nil?
        credentials = get_api_credentials
        caller = get_api_id_owner(credentials) unless credentials.nil?
      else
        caller = token.target
      end
      # unless caller.nil?
      #   if caller.kind_of?(Client)
      #     log.debug "Caller is a client with the name '#{caller.name}' (id: #{caller.id})."
      #   else
      #     log.debug "Caller is a user with the name '#{caller.fullname}' (id: #{caller.id})."
      #   end
      # end
      caller
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
      token = nil
      #log.debug "Fetching access token. Checking for an authorization header in the request."
      if request.headers.include?("Authorization")
        #log.debug "Found an authorization header."
        values = request.headers["Authorization"].split
        values[0] = values[0].downcase
        #log.debug "Authorization header type: #{values[0]}"
        if values[0] == "bearer"
          #log.debug "Fetching the access token for '#{values[1]}'."
          token = AccessToken.where(request: values[1]).first
        end
      else
        #log.debug "No authorization header found, checking for API credentials."
        credentials = get_api_credentials
        unless credentials.nil?
          cached_token = Evercam::Services.dalli_cache.get(credentials.to_s)
          unless cached_token.nil?
            #log.info "Token taken from cache."
            return cached_token
          end
          owner = get_api_id_owner(credentials)
          unless owner.nil?
            if owner.instance_of?(User)
              token = owner.token
            else
              token = AccessToken.where(client_id: owner.id).order(Sequel.desc(:created_at)).first
            end
            Evercam::Services.dalli_cache.set(credentials.to_s, token, 5 * 60)
          end
        end
      end
      token = nil if token && token.is_revoked?
      #log.info "An valid access token was NOT found for request." if token.nil?
      token
    end

    # This method checks for an extracts API credentials from the parameters
    # passed for a request.
    def get_api_credentials
      credentials = nil
      parameters = request.params
      #log.debug "Checking request parameters for API credentials."
      if parameters.include?(:api_id) && parameters.include?(:api_key)
        credentials = {api_id: parameters[:api_id],
                       api_key: parameters[:api_key]}
      end
      credentials
    end

    # This method fetches the owner for a specified API id. The method also
    # incorporates a check that the api_key is valid, returning nil if this
    # is not the case.
    def get_api_id_owner(credentials)
      #log.debug "Fetching owner for API id '#{credentials[:api_id]}'."
      query = Client.where(api_id: credentials[:api_id])
      if query.count == 0
        #log.debug "API id does not belong to a client, checking for a user."
        owner = User.where(api_id: credentials[:api_id]).first
      else
        #log.debug "API credentials belong to a client, fetching their details."
        owner = query.first
      end
      owner = nil if !owner.nil? && !valid_api_credentials?(owner, credentials)

      #log.info "No owner found for API credentials." if owner.nil?
      owner
    end

    # This method determines whether a API id/key set are valid for a given
    # credentials owner.
    def valid_api_credentials?(owner, credentials)
      result = false
      if owner
        result = (owner.api_id == credentials[:api_id] &&
          owner.api_key == credentials[:api_key])
      end
      result
    end
  end
end
