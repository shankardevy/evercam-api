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
          optional :case_sensitive, type: 'Boolean', desc: "Set whether search terms are case sensitive. Defaults to true."
          optional :id_starts_with, type: String, desc: "Search for cameras whose id starts with the given value."
          optional :id_ends_with, type: String, desc: "Search for cameras whose id ends with the given value."
          optional :id_contains, type: String, desc: "Search for cameras whose id contains the given value."
          optional :is_near_to, type: String, desc: "Search for cameras within #{DEFAULT_DISTANCE} meters of a given address or longitude latitiude point."
          optional :within_distance, type: Float, desc: "Search for cameras within a specific range, in meters, of the is_near_to point."
        end
        get do
          query = Camera.where(is_public: true, discoverable: true)
          case_sensitive = params.include?(:case_sensitive) ? params[:case_sensitive] : true

          if params[:id_starts_with]
            query = case_sensitive ?
              query.where(Sequel.like(:exid, "#{params[:id_starts_with]}%")) :
              query.where(Sequel.like(Sequel.function(:lower, :exid), "#{params[:id_starts_with].downcase}%"))
          end

          if params[:id_ends_with]
            query = case_sensitive ?
              query.where(Sequel.like(:exid, "%#{params[:id_ends_with]}")) :
              query.where(Sequel.like(Sequel.function(:lower, :exid), "%#{params[:id_ends_with].downcase}"))
          end

          if params[:id_includes]
            query = case_sensitive ?
              query.where(Sequel.like(:exid, "%#{params[:id_includes]}%")) :
              query.where(Sequel.like(Sequel.function(:lower, :exid), "%#{params[:id_includes].downcase}%"))
          end

          if params[:is_near_to]
            begin
              query = query.by_distance(params[:is_near_to], params[:within_distance] || DEFAULT_DISTANCE)
            rescue ArgumentError => ex
              raise_error(400, 400, ex.message)
            end
          end

          limit = (params[:limit] || DEFAULT_LIMIT)
          limit = (limit > MAXIMUM_LIMIT ? MAXIMUM_LIMIT : DEFAULT_LIMIT) unless (1..MAXIMUM_LIMIT).include?(limit)

          total_pages = query.count / limit
          total_pages += 1 unless query.count % limit == 0

          offset = (params[:offset] && params[:offset] >= 0) ? params[:offset] : DEFAULT_OFFSET
          query = query.offset(offset).limit(limit)

          log.debug "SQL: #{query.sql}"
          present(query.all.to_a, with: Presenters::Camera, minimal: true).merge!({
            :pages => total_pages
          })
        end
      end
    end
  end
end

