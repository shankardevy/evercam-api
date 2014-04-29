require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
   class V1ShareRoutes < Grape::API
      include WebErrors

      resource :shares do
         before do
            authorize!
         end

         resource :camera do
            #-------------------------------------------------------------------
            # GET /shares/camera/:id
            #-------------------------------------------------------------------
            desc 'Get the list of shares for a specified camera', {
              entity: Evercam::Presenters::CameraShare
            }
            params do
              requires :id, type: String, desc: "The unique identifier for a camera."
            end
            get '/:id' do
              authreport!('shares/get')

              camera = ::Camera.by_exid!(params[:id])
              rights = requester_rights_for(camera)
              raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

              shares = CameraShare.where(camera_id: camera.id).to_a
              present shares, with: Presenters::CameraShare
            end

            #-------------------------------------------------------------------
            # POST /shares/camera/:id
            #-------------------------------------------------------------------
            desc 'Create a new camera share', {
              entity: Evercam::Presenters::CameraShare
            }
            params do
              requires :email, type: String, desc: "Email address of user to share the camera with."
              requires :rights, type: String, desc: "A comma separate list of the rights to be granted with the share."
              optional :message, String, desc: "Not currently used."
              optional :notify, type: Boolean, desc: "Not currently used."
              optional :grantor, type: String, desc: "The user name of the user who is creating the share."
            end
            post '/:id' do
              authreport!('share/post')

              camera = ::Camera.by_exid!(params[:id])
              rights = requester_rights_for(camera)
              if !(camera.is_public? && camera.discoverable?) && !rights.is_owner?
                 raise AuthorizationError.new
              end

              outcome = Actors::ShareCreate.run(params)
              raise OutcomeError, outcome unless outcome.success?

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
            end
            delete '/:id' do
              authreport!('share/delete')

              camera = ::Camera.by_exid!(params[:id])
              rights = requester_rights_for(camera)
              raise AuthorizationError.new if !rights.is_owner?

              Actors::ShareDelete.run(params)
              {}
            end

            #-------------------------------------------------------------------
            # PATCH /shares/camera/:id
            #-------------------------------------------------------------------
            desc 'Update an existing camera share (COMING SOON)'
            patch '/:id' do
              raise ComingSoonError
            end
         end

         resource :user do
            #-------------------------------------------------------------------
            # GET /shares/user/:id
            #-------------------------------------------------------------------
            desc 'Fetch the list of shares currently granted to a user.', {
               entity: Evercam::Presenters::CameraShare
            }
            params do
               requires :id, type: String, desc: "The unique identifier of the user to fetch the list of shares for."
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
            end
            get '/:id' do
               authreport!('share_requests/get')

               camera = Camera.by_exid!(params[:id])
               rights = requester_rights_for(camera)
               raise AuthorizationError.new if !rights.allow?(AccessRight::VIEW)

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
               present (query.to_a || []), with: Presenters::CameraShareRequest
            end
         end
      end
   end
end