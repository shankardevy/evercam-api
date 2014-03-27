require_relative '../presenters/user_presenter'
require_relative '../presenters/camera_presenter'

module Evercam
   class V1ClientRoutes < Grape::API
   	resource :client do
	      before do
	        authorize!
	      end

         helpers do
            include ThreeScaleHelper
         end

         #----------------------------------------------------------------------
         # POST /v1/client
         #----------------------------------------------------------------------
   		desc "Create a new client record in the system.", {hidden: true}
   		params do
   			requires :name, type: String, desc: "The name for the new client."
   			requires :callback_uris, type: Array, desc: "A comma separated list of callback URIs and host names."
   			requires :user_name, type: String, desc: "The user name to be assigned to the client."
   			requires :email, type: String, desc: "The primary contact email address for the client."
   			optional :password, type: String, desc: "The password to assign to the client (on 3Scale)."
   		end
   		post do
   			raise ConflictError.new if Client.where(name: params[:name]).count > 0

   			values = threescale_signup_client(params[:name],
   				                               params[:user_name],
   				                               params[:email],
   				                               params[:password])
   			uris   = nil
   			if params[:callback_uris]
   				uris = []
   				params[:callback_uris].each {|entry| uris << entry.strip}
   			end
   			client = Client.create(exid: values[:exid],
   				                    secret: values[:secret],
   				                    name: params[:name],
   				                    callback_uris: uris)
   			status = 201
   			{id: client.exid, api_key: client.secret}
   		end

         route_param :id do
	         #-------------------------------------------------------------------
	         # GET /v1/client/:id
	         #-------------------------------------------------------------------
	         desc "Get details for a client based on their id.",
	              {entity: Evercam::Presenters::Client, hidden: true}
	         params do
	         	requires :id, type: String, desc: "The unique identifier for the client to retrieve details for."
	         end
	         get do
	         	client = Client.where(exid: params[:id]).first
	         	raise NotFoundError.new if client.nil?
	         	present client, with: Presenters::Client
	         end

	         #-------------------------------------------------------------------
	         # DELETE /v1/client/:id
	         #-------------------------------------------------------------------
	         desc "Deletes an existing client from the system.",
	              {entity: Evercam::Presenters::Client, hidden: true}
	         params do
	         	requires :id, type: String, desc: "The unique identifier for the client to be deleted."
	         end
	         delete do
	         	client = Client.where(exid: params[:id]).first
	         	client.destroy if !client.nil?
	         	{}
	         end

            #-------------------------------------------------------------------
            # PATCH /v1/client/:id
            #-------------------------------------------------------------------
            desc "Update an existing clients details.",
                 {entity: Evercam::Presenters::Client, hidden: true}
            params do
               requires :id, type: String, desc: "The unique identifier for the client to be updated."
               optional :name, type: String, desc: "The new name for the client."
               optional :callback_uris, type: String, desc: "A comma separated list of callback URIs and host names."
            end
            patch do
               client = Client.where(exid: params[:id]).first
               raise NotFoundError.new if client.nil?

               changed = false
               if params.include?(:name)
                  if client.name != params[:name]
                     client.name = params[:name]
                     changed = true
                  end
               end

               if params.include?(:callback_uris)
                  uris = params[:callback_uris].split(",").inject([]) do |list, entry|
                     list << entry.strip
                  end
                  if uris.sort != client.callback_uris.sort
                     client.callback_uris = uris
                     changed = true
                  end
               end

               client.save if changed
               {}
            end
	      end
   	end
   end
end