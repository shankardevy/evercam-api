module Evercam
   # This module contains helpers methods that are specific to the user of the
   # 3Scale API. Note that the methods in this helper are dependent on methods
   # defined in the authorization helper so if you want to use this helper you
   # also have to include that one.
   module ThreeScaleHelper
      @@client = ThreeScale::Client.new(provider_key: Evercam::Config[:threescale][:provider_key])

      # This method validates a requesters 3Scale credentials.
   	def authreport!(method_name='hits', usage_value=1)
   		credentials = get_3scale_credentials
   		if !credentials.nil?
	         response = @@client.authrep(credentials.merge({method_name => usage_value}))
	         puts response.error_message unless response.success? || Evercam::Config.env == :test
	      end
   	end

      # This method fetches the 3Scale API credentials for a request. It will
      # first check for these in the request parameters and, if they are not
      # found, then fall back on looking them up via other means.
   	def get_3scale_credentials
   		if !params.include?('app_id')
   			credentials = nil
   			token       = access_token
   			if !token.nil?
	   			entity = token.target
	   			if entity.instance_of?(User)
	   				{app_id: entity.api_id, app_key: entity.api_key}
	   			else
	   				{app_id: entity.exid, app_key: entity.secret}
	   			end
	   		end
	   		credentials
   		else
   			{app_id: params['app_id'], app_key: params['app_key']}
   		end
   	end
   end
end