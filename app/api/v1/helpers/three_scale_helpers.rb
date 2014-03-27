module Evercam
   # This module contains helpers methods that are specific to the user of the
   # 3Scale API. Note that the methods in this helper are dependent on methods
   # defined in the authorization helper so if you want to use this helper you
   # also have to include that one.
   module ThreeScaleHelper
      @@client = ThreeScale::Client.new(provider_key: Evercam::Config[:threescale][:provider_key])

      # This method validates a requesters 3Scale credentials.
   	def authreport!(method_name='hits', usage_value=1)
   		#credentials = get_3scale_credentials
   		#if !credentials.nil?
	      #   response = @@client.authrep(credentials.merge({method_name => usage_value}))
	      #   puts response.error_message unless response.success? || Evercam::Config.env == :test
	      #end
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
   				{app_id: entity.api_id, app_key: entity.api_key}
	   		end
	   		credentials
   		else
   			{app_id: params['app_id'], app_key: params['app_key']}
   		end
   	end

      # This method creates a new sign up record for a client on 3Scale and
      # returns the application id, application key and assigned password as
      # a Hash.
      def threescale_signup_client(organization, user_name, email, password=nil)
         password ||= SecureRandom.hex(10)
         parameters = get_parameters(org_name: organization,
                                     username: user_name,
                                     email:    email,
                                     password: password)
         response   = get_faraday_connection.post('/admin/api/signup.xml', parameters)
         if !(200..299).include?(response.status)
           raise Evercam::WebErrors::BadRequestError, response.body
         end
         document = Nokogiri::XML(response.body)
         {account_id: document.xpath("/account/id").text,
          email: email,
          exid: document.xpath("/account/applications/application[1]/application_id").text,
          secret: document.xpath("/account/applications/application[1]/keys/key[1]").text,
          password: password,
          user_name: user_name}
      end

      # This method deletes an account from 3Scale and requires the account id
      # to do it.
      def threescale_delete_account(account_id)
         response = get_faraday_connection.delete("/admin/api/accounts/#{account_id}.xml",
                                                  get_parameters)
         if !(200..299).include?(response.status)
            raise Evercam::WebErrors.BadRequestError.new(response.body)
         end
      end


      # Get a Faraday connection object for the 3Scale base URL.
      def get_faraday_connection
         Faraday.new(Evercam::Config[:threescale][:url])
      end

      # Get the base set of parameters needed for a 3Scale request. At the
      # moment this simply generates a Hash containing the 3Scale provider
      # key.
      def get_base_parameters
         {provider_key: Evercam::Config[:threescale][:provider_key]}
      end

      # Generate a parameters Hash for a request to 3Scale. The automatically
      # folds in the parmaeters from the get_base_parameters() method so that
      # these don't have to be explicitly included.
      def get_parameters(values={})
         get_base_parameters.merge(values)
      end
   end
end