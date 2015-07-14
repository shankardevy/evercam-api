require_relative '../presenters/camera_presenter'
require_relative '../presenters/camera_share_presenter'

module Evercam
  class V1PublicRoutes < Grape::API
    include WebErrors

    DEFAULT_OFFSET = 0
    DEFAULT_LIMIT = 100
    MAXIMUM_LIMIT = 1000
    DEFAULT_DISTANCE = 1000

    resource :public do
      resource :cameras do
        #-------------------------------------------------------------------
        # GET /v1/public/cameras
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
          optional :is_near_to, type: String, desc: "Search for cameras within #{DEFAULT_DISTANCE} meters of a given address or latitude longitude point."
          optional :within_distance, type: Float, desc: "Search for cameras within a specific range, in meters, of the is_near_to point."
          optional :thumbnail, type: 'Boolean', desc: "Set to true to get base64 encoded 150x150 thumbnail with camera view or null if it's not available."
        end
        get do
          query_result = nil
          total_pages = nil
          count = nil
          unless params.include?(:thumbnail) || params[:thumbnail]
            params_copy = params.clone
            params_copy.delete(:route_info)
            cache_key = "public|#{params_copy.flatten.join('|')}"
            query_result = Evercam::Services.dalli_cache.get(cache_key)
            total_pages = Evercam::Services.dalli_cache.get("#{cache_key}|pages")
            count = Evercam::Services.dalli_cache.get("#{cache_key}|records")
          end
          if query_result.nil? || total_pages.nil? || count.nil?
            query = Camera.where(is_public: true, discoverable: true)
            unless params[:thumbnail]
              query = query.select(
                Sequel.qualify(:cameras, :id),
                Sequel.qualify(:cameras, :created_at),
                Sequel.qualify(:cameras, :updated_at),
                :exid,
                :owner_id, :is_public, :config,
                :name, :last_polled_at, :is_online,
                :timezone, :last_online_at, :location,
                :mac_address, :model_id, :discoverable, :thumbnail_url
              )
            end
            case_sensitive = params.include?(:case_sensitive) ? params[:case_sensitive] : true
            is_like = case_sensitive ? :like : :ilike

            begin
              query = query.where(Sequel.send(is_like, :exid, "#{params[:id_starts_with]}%")) if params[:id_starts_with]
              query = query.where(Sequel.send(is_like, :exid, "%#{params[:id_ends_with]}")) if params[:id_ends_with]
              query = query.where(Sequel.send(is_like, :exid, "%#{params[:id_includes]}%")) if params[:id_includes]
              query = query.by_distance(params[:is_near_to], params[:within_distance] || DEFAULT_DISTANCE) if params[:is_near_to]
            rescue Exception => ex
              raise_error(400, 400, ex.message)
            end

            limit = (params[:limit] || DEFAULT_LIMIT)
            limit = (limit > MAXIMUM_LIMIT ? MAXIMUM_LIMIT : DEFAULT_LIMIT) unless (1..MAXIMUM_LIMIT).include?(limit)

            count = query.count
            total_pages = count / limit
            total_pages += 1 unless count % limit == 0
            offset = (params[:offset] && params[:offset] >= 0) ? params[:offset] : DEFAULT_OFFSET
            query = query.offset(offset).limit(limit)
            query_result = query.eager(:owner).eager(:vendor_model => :vendor).all.to_a
            unless params.include?(:thumbnail) || params[:thumbnail]
              Evercam::Services.dalli_cache.set(cache_key, query_result)
              Evercam::Services.dalli_cache.set("#{cache_key}|pages", total_pages)
              Evercam::Services.dalli_cache.set("#{cache_key}|records", count)
            end
          end
          present(query_result, with: Presenters::Camera, minimal: true, thumbnail: params[:thumbnail]).merge!(pages: total_pages, records: count)
        end

        #-------------------------------------------------------------------
        # GET /v1/public/cameras/nearest
        #-------------------------------------------------------------------
        desc "Fetch nearest publicly discoverable camera from within the Evercam system."\
             "If location isn't provided requester's IP address is used.", {
            entity: Evercam::Presenters::Camera
          }
        params do
          optional :near_to, type: String, desc: "Specify an address or latitude longitude points."
        end
        get 'nearest' do
          params_copy = params.clone
          params_copy.delete(:route_info)
          params_copy.merge!(request.location.data) if request.location
          cache_key = "public|#{params_copy.flatten.join('|')}"
          query_result = Evercam::Services.dalli_cache.get(cache_key)
          begin
            if params[:near_to]
              location = {
                latitude: Geocoding.as_point(params[:near_to]).y,
                longitude: Geocoding.as_point(params[:near_to]).x
              }
              location_message = "Successfully Geocoded #{params[:near_to]} as LAT: #{location[:latitude]} LNG: #{location[:longitude]}"
            else
              if request.location
                location = {
                  latitude: request.location.latitude,
                  longitude: request.location.longitude
                }
                location_message = "Successfully Geocoded IP Address #{request.location.ip} as LAT: #{location[:latitude]} LNG: #{location[:longitude]}"
              else
                raise_error(400, 400, "There was an error decoding your IP address. Please try specifying a location using near_to parameter.")
              end
            end
          rescue Exception => ex
            raise_error(400, 400, ex.message)
          end

          if query_result.nil?
            if params[:near_to] or request.location
              query = Camera.nearest(location).limit(1)
            else
              raise_error(400, 400, "Location is missing")
            end

            query_result = query.eager(:owner).eager(:vendor_model => :vendor).all.to_a
            Evercam::Services.dalli_cache.set(cache_key, query_result)
          end
          present(query_result, with: Presenters::Camera, minimal: true, thumbnail: true).merge!({
              message: location_message
            })
        end
      end
    end
  end
end
