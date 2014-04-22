require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
   class V1TestRoutes < Grape::API
      include WebErrors

      resource :test do
      	desc "A simple endpoint that can be used to test whether an API id "\
      	     "and key pair are valid."
      	params do
      		optional :api_id, type: String, desc: "The API id to be tested."
      		optional :api_key, type: String, desc: "The API key to be tested."
      	end
	      get do
	      	result = {authenticated: false,
	      	          source_ip: request.ip,
	      	          timestamp: Time.now.to_s}
	      	query = Client.where(api_id: params[:api_id])
	      	if query.count == 0
	      		user = User.where(api_id: params[:api_id]).first
	      		if !user.nil?
	      		   result[:authenticated] = (user.api_key == params[:api_key])
	      		end
	      	else
	      		client = query.first
	      		result[:authenticated] = (client.api_key == params[:api_key]) if !client.nil?
	      	end
	      	result
	      end
	   end
   end
end