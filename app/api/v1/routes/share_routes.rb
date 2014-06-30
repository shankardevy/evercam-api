require "evercam_sidekiq"
require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
   class V1ShareRoutes < Grape::API
      include WebErrors

      resource :shares do
         before do
            authorize!
         end

         #----------------------------------------------------------------------
         # GET /shares
         #----------------------------------------------------------------------
         desc 'Get details for a share for a specific camera and user.', {
            entity: Evercam::Presenters::CameraShare
         }
         params do
            requires :camera_id, type: String, desc: 'The unique identifier for the camera in the share.'
            requires :user_id, type: String, desc: 'The unique identifier for the user the camera is shared with.'
         end
         get do
            authreport!('shares/get')

            camera = Camera.by_exid!(params[:camera_id])
            user   = User.by_login(params[:user_id])
            raise NotFoundError.new("User does not exist.") if !user

            rights    = requester_rights_for(camera)
            requester = caller
            if !rights.allow?(AccessRight::LIST) &&
               (requester.email != params[:user_id] && requester.username != params[:user_id])
               raise AuthorizationError.new
            end

            shares = CameraShare.where(camera_id: camera.id, user_id: user.id).to_a
            present shares, with: Presenters::CameraShare
         end

         resource :cameras do
            #-------------------------------------------------------------------
            # GET /shares/cameras/:id
            #-------------------------------------------------------------------
            desc 'Get the list of shares for a specified camera', {
              entity: Evercam::Presenters::CameraShare
            }
            params do
              requires :id, type: String, desc: "The unique identifier for a camera."
              optional :api_id, type: String, desc: "The Evercam API id for the requester."
              optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            get '/:id' do
              authreport!('shares/get')

              camera = ::Camera.by_exid!(params[:id])
              rights = requester_rights_for(camera)
              shares = []
              if rights.allow?(AccessRight::VIEW)
                shares = CameraShare.eager(:camera, :user, :sharer).where(camera_id: camera.id).association_join(:camera).all.to_a
              end
              present shares, with: Presenters::CameraShare
            end

            #-------------------------------------------------------------------
            # POST /shares/cameras/:id
            #-------------------------------------------------------------------
            desc 'Create a new camera share', {
              entity: Evercam::Presenters::CameraShare
            }
            params do
              requires :email, type: String, desc: "Email address or user name of the user to share the camera with."
              requires :rights, type: String, desc: "A comma separate list of the rights to be granted with the share."
              optional :message, String, desc: "Not currently used."
              optional :notify, type: 'Boolean', desc: "Not currently used."
              optional :grantor, type: String, desc: "The user name of the user who is creating the share."
              optional :api_id, type: String, desc: "The Evercam API id for the requester."
              optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            post '/:id' do
              authreport!('share/post')
              camera = ::Camera.by_exid!(params[:id])
              rights = requester_rights_for(camera)
              if !rights.is_owner? && !rights.allow?(AccessRight::EDIT) &&
                # Quick hack to allow following public cameras
                !(camera.is_public && params[:rights] == 'list,snapshot')
                 raise AuthorizationError.new
              end
              if User.by_login(params[:email]) == camera.owner
                raise BadRequestError.new("You can't share with yourself",
                                          "cant_share_with_yourself",
                                          params[:email])
              end

              outcome = Actors::ShareCreate.run(params)
              unless outcome.success?
                raise_error(400, "invalid_parameters",
                            "Invalid parameters specified to request.",
                            *(outcome.errors.keys))
              end

              grantor = (params[:grantor] ? User.where(username: params[:grantor]).first : camera.owner)
              CameraActivity.create(
                camera: camera,
                access_token: grantor.token,
                action: 'shared',
                done_at: Time.now,
                ip: request.ip,
                extra: {:with => params[:email]}
              )
              IntercomEventsWorker.perform_async('shared-camera', caller.email)
              if outcome.result.class == CameraShare
                present [outcome.result], with: Presenters::CameraShare
              else
                present [outcome.result], with: Presenters::CameraShareRequest
              end
            end

            #-------------------------------------------------------------------
            # DELETE /shares/camera/:id
            #-------------------------------------------------------------------
            desc 'Delete an existing camera share', {}
            params do
              requires :id, type: String, desc: "The unique identifier for a camera."
              requires :share_id, type: Integer, desc: "The unique identifier of the share to be deleted."
              optional :api_id, type: String, desc: "The Evercam API id for the requester."
              optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            delete '/:id' do
              authreport!('share/delete')

              camera = ::Camera.by_exid!(params[:id])
              share  = CameraShare.where(id: params[:share_id]).first
              if share
                requester = caller
                if camera.owner_id != requester.id && share.user_id != requester.id
                  raise AuthorizationError.new
                end
              end

              Actors::ShareDelete.run(params.merge!({:ip => request.ip}))
              {}
            end

            #-------------------------------------------------------------------
            # PATCH /shares/cameras/:id
            #-------------------------------------------------------------------
            desc 'Update an existing camera share.', {}
            params do
               requires :id, type: Integer, desc: "The unique identifier of the camera share to be updated."
               requires :rights, type: String, desc: "A comma separate list of the rights to be set on the share."
               optional :api_id, type: String, desc: "The Evercam API id for the requester."
               optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            patch '/:id' do
               authreport!('share/update')

               share  = CameraShare.where(id: params[:id]).first
               raise NotFoundError.new if share.nil?

               rights = requester_rights_for(share.camera)
               if !(rights.is_public? && share.camera.discoverable?) && !rights.is_owner?
                  raise AuthorizationError.new
               end

               outcome = Actors::ShareUpdate.run(params.merge!({:ip => request.ip}))
               if !outcome.success?
                  raise_error(400, "invalid_parameters",
                              "Invalid parameters specified for request.",
                              *(outcome.errors.keys))
               end

               present [outcome.result], with: Presenters::CameraShare
            end
         end

         resource :users do
            #-------------------------------------------------------------------
            # GET /shares/users/:id
            #-------------------------------------------------------------------
            desc 'Fetch the list of shares currently granted to a user.', {
               entity: Evercam::Presenters::CameraShare
            }
            params do
               requires :id, type: String, desc: "The unique identifier of the user to fetch the list of shares for."
               optional :api_id, type: String, desc: "The Evercam API id for the requester."
               optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            get '/:id' do
               authreport!('shares/get')

               user   = User.by_login(params[:id])
               raise NotFoundError.new if user.nil?
               rights = requester_rights_for(user, AccessRight::CAMERAS)
               raise AuthorizationError.new if !rights.allow?(AccessRight::LIST)

               shares = CameraShare.where(user_id: user.id)
               present shares.to_a, with: Presenters::CameraShare
            end
         end

         resource :requests do
            #-------------------------------------------------------------------
            # GET /shares/requests/:id
            #-------------------------------------------------------------------
            desc 'Fetch the list of share requests currently outstanding for a given camera.', {
               entity: Evercam::Presenters::CameraShareRequest
            }
            params do
               requires :id, type: String, desc: "The unique identifier of the camera to fetch share requests for."
               optional :status, type: String, desc: "The request status to fetch, either 'PENDING', 'USED' or 'CANCELLED'."
               optional :api_id, type: String, desc: "The Evercam API id for the requester."
               optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            get '/:id' do
               authreport!('share_requests/get')

               camera = Camera.by_exid!(params[:id])
               rights = requester_rights_for(camera)
               list   = []
               if rights.allow?(AccessRight::VIEW)
                 query = CameraShareRequest.where(camera_id: camera.id)
                 if params[:status]
                    case params[:status].downcase
                       when 'used'
                          query = query.where(status: CameraShareRequest::USED)
                       when 'cancelled'
                          query = query.where(status: CameraShareRequest::CANCELLED)
                       else
                          query = query.where(status: CameraShareRequest::PENDING)
                    end
                 end
                 log.debug "Query: #{query.sql}"
                 list = query.to_a
               end
               present list, with: Presenters::CameraShareRequest
            end

            #-------------------------------------------------------------------
            # DELETE /shares/requests/:id
            #-------------------------------------------------------------------
            desc 'Cancels a pending camera share request for a given camera', {
               entity: Evercam::Presenters::CameraShareRequest
            }
            params do
               requires :id, type: String, desc: "The unique identifier of the camera to fetch share requests for."
               requires :email, type: String, desc: "The email address of user the camera was shared with."
               optional :api_id, type: String, desc: "The Evercam API id for the requester."
               optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            delete '/:id' do
               authreport!('share_requests/delete')

               camera = Camera.by_exid!(params[:id])
               rights = requester_rights_for(camera)
               raise AuthorizationError.new if !rights.allow?(AccessRight::EDIT)

               share_request = CameraShareRequest.where(status: CameraShareRequest::PENDING,
                                                        email: params[:email],
                                                        camera: camera).first
               raise NotFoundError.new if share_request.nil?

               log.debug "Marking camera share request id #{share_request.id} as cancelled."
               share_request.update(status: CameraShareRequest::CANCELLED)
               {}
            end

            #-------------------------------------------------------------------
            # PATCH /shares/requests/:id
            #-------------------------------------------------------------------
            desc 'Updates a pending camera share request.', {
               entity: Evercam::Presenters::CameraShareRequest
            }
            params do
               requires :id, type: String, desc: "The unique identifier of the camera share request to update."
               requires :rights, type: String, desc: "The new set of rights to be granted for the share."
               optional :api_id, type: String, desc: "The Evercam API id for the requester."
               optional :api_key, type: String, desc: "The Evercam API key for the requester."
            end
            patch '/:id' do
               authreport!('share_requests/delete')

               share_request = CameraShareRequest.where(key: params[:id]).first
               raise NotFoundError.new if share_request.nil?

               rights = requester_rights_for(share_request.camera)
               if !(rights.is_public? && share_request.camera.discoverable?) && !rights.is_owner?
                  raise AuthorizationError.new
               end

               params[:rights].split(",").each do |right|
                  raise BadRequestError.new if !rights.valid_right?(right.strip.downcase)
               end

               share_request.update(rights: params[:rights])
               present [share_request], with: Presenters::CameraShareRequest
            end
         end
      end
   end
end