require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
  class V1PublicRoutes < Grape::API
    include WebErrors

    DEFAULT_OFFSET         = 0
    DEFAULT_LIMIT          = 100
    MAXIMUM_LIMIT          = 1000
    DEFAULT_DISTANCE       = 1000

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
          optional :is_near_to, type: String, desc: "Search for cameras within #{DEFAULT_DISTANCE} meters of a given address or longitude latitiude point."
          optional :within_distance, type: Float, desc: "Search for cameras within a greater range of the specified is_near_to point in meters."
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

          if params.include?(:is_near_to) && params[:is_near_to]
            if params.include?(:within_distance) && params[:within_distance]
              query = query.by_distance(params[:is_near_to], params[:within_distance])
            else
              query = query.by_distance(params[:is_near_to], DEFAULT_DISTANCE)
            end
          end

          limit = (params[:limit] || DEFAULT_LIMIT)
          if !(1..MAXIMUM_LIMIT).include?(limit)
            limit = (limit > MAXIMUM_LIMIT ? MAXIMUM_LIMIT : DEFAULT_LIMIT)
          end
          total_pages = query.count / limit
          offset      = (params[:offset] && params[:offset] >= 0) ? params[:offset] : DEFAULT_OFFSET
          query = query.offset(offset)

          query = query.limit(limit)

          log.debug "SQL: #{query.sql}"
          present(query.all.to_a, with: Presenters::Camera, minimal: true).merge!({
            :pages => total_pages
          })
        end
      end
    end
  end
end
