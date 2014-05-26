require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
   class V1PublicRoutes < Grape::API
      include WebErrors

      DEFAULT_OFFSET         = 0
      DEFAULT_LIMIT          = 100
      MAXIMUM_LIMIT          = 1000

      resource :public do
         resource :cameras do
            #-------------------------------------------------------------------
            # GET /public/cameras
            #-------------------------------------------------------------------
            desc "Fetch a list of publicly discoverable cameras from within the Evercam system.", {
               entity: Evercam::Presenters::Camera
            }
            params do
               optional :offset, type: Integer, desc: "The offset into the list of cameras to start the fetch from. Defaults to #{DEFAULT_OFFSET}."
               optional :limit, type: Integer, desc: "The maximum number of cameras to retrieve. Defaults to #{DEFAULT_LIMIT}, cannot be more than #{MAXIMUM_LIMIT}."
               optional :case_sensitive, type: Boolean, desc: "Set whether search terms are case sensitive. Defaults to true."
               optional :id_starts_with, type: String, desc: "Search for cameras whose id starts with the given value."
               optional :id_ends_with, type: String, desc: "Search for cameras whose id ends with the given value."
               optional :id_contains, type: String, desc: "Search for cameras whose id contains the given value."
            end
            get do
               case_sensitive = (params.include?(:case_sensitive) ? params[:case_sensitive] : true)

               query = Camera.where(is_public: true, discoverable: true)

               if params.include?(:id_starts_with) && params[:id_starts_with]
                  if case_sensitive
                     query = query.where(Sequel.like(:exid, "#{params[:id_starts_with]}%"))
                  else
                     query = query.where(Sequel.like(Sequel.function(:lower, :exid), "#{params[:id_starts_with].downcase}%"))
                  end
               end

               if params.include?(:id_ends_with) && params[:id_ends_with]
                  if case_sensitive
                     query = query.where(Sequel.like(:exid, "%#{params[:id_ends_with]}"))
                  else
                     query = query.where(Sequel.like(Sequel.function(:lower, :exid), "%#{params[:id_starts_with].downcase}"))
                  end
               end

               if params.include?(:id_includes) && params[:id_includes]
                  if case_sensitive
                     query = query.where(Sequel.like(:exid, "%#{params[:id_includes]}%"))
                  else
                     query = query.where(Sequel.like(Sequel.function(:lower, :exid), "%#{params[:id_includes].downcase}%"))
                  end
               end

               limit = (params[:limit] || DEFAULT_LIMIT)
               total_pages = query.count / limit
               query = query.offset(params[:offset] || DEFAULT_OFFSET)

               query = query.limit(limit > MAXIMUM_LIMIT ? MAXIMUM_LIMIT : limit)

               log.debug "SQL: #{query.sql}"
               present(query.all.to_a, with: Presenters::Camera, minimal: true).merge!({
                 :pages => total_pages
               })
            end
         end
      end
   end
end