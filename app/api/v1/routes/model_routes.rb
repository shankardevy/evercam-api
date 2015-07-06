require_relative '../presenters/model_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 25

    #---------------------------------------------------------------------------
    # GET /v1/models
    #---------------------------------------------------------------------------
    desc 'Returns set of known models for a supported camera vendor', {
        entity: Evercam::Presenters::Model
      }
    params do
      optional :name, type: String, desc: "Name of the model (partial search)"
      optional :vendor_id, type: String, desc: "Unique identifier for the vendor"
      optional :limit, type: Integer, desc: "Number of results per page. Defaults to #{DEFAULT_LIMIT}."
      optional :page, type: Integer, desc: "Page number, starting from 0"
    end
    get '/models' do
      authreport!('models/vendor/get')
      limit = params[:limit] || DEFAULT_LIMIT
      page = params[:page] || 0
      page = 0 if page < 0
      limit = DEFAULT_LIMIT if limit < 1
      v_id = params.fetch(:vendor_id, nil)
      vendor = nil
      unless v_id.nil?
        vendor = ::Vendor.by_exid(v_id).first
        raise NotFoundError, 'model vendor was not found' unless vendor
      end
      models = ::VendorModel.eager(:vendor)
      models = models.where(vendor_id: vendor.id) unless vendor.nil?
      models = models.where(Sequel.ilike(:name, "%#{params[:name]}%")) unless params.fetch(:name, nil).nil?
      models = models.where(exid: params[:id]) unless params.fetch(:id, nil).nil?
      total_pages = models.count / limit
      models = models.limit(limit, page*limit)
      present(Array(models.all), with: Presenters::Model).merge!({ :pages => total_pages})
    end

    #---------------------------------------------------------------------------
    # GET /v1/models/:id
    #---------------------------------------------------------------------------
    desc 'Returns available information for the specified model', {
        entity: Evercam::Presenters::Model
      }
    params do
      requires :id, type: String, desc: "Unique identifier for the model"
    end
    get '/models/:id' do
      model = VendorModel.where(exid: params[:id]).first
      raise Evercam::NotFoundError.new("Unable to locate the '#{params[:id]}' model.",
          "model_not_found_error", params[:id]) if model.blank?
      present(Array(model), with: Presenters::Model)
    end

    resource :models do

      before do
        authorize!
      end

      #---------------------------------------------------------------------------
      # POST /v1/models
      #---------------------------------------------------------------------------
      desc 'Create a new model', {
          entity: Evercam::Presenters::Model
        }
      params do
        requires :id, type: String, desc: "Unique identifier for the model"
        requires :vendor_id, type: String, desc: "Unique identifier for the vendor"
        requires :name, type: String, desc: "Name of the model"
        optional :jpg_url, type: String, desc: "Snapshot url"
        optional :mjpg_url, type: String, desc: "Mjpg url"
        optional :mpeg4_url, type: String, desc: "MPEG4 url"
        optional :mobile_url, type: String, desc: "Mobile url"
        optional :h264_url, type: String, desc: "H264 url"
        optional :lowres_url, type: String, desc: "Low resolution url"
        optional :default_username, type: String, desc: "Default Username"
        optional :default_password, type: String, desc: "Default Password"
        optional :shape, type: String, desc: "Shape of the model"
        optional :resolution, type: String, desc: "Resolution(s) supported by model"
        optional :official_url, type: String, desc: "Official URL of model details"
        optional :audio_url, type: String, desc: "Audio stream URL of the model"
        optional :more_info, type: String, desc: "Additional information of the model"
        optional :poe, type: 'Boolean', desc: "Whether or not POE is supported by the model"
        optional :wifi, type: 'Boolean', desc: "Whether or not WiFi is supported by the model"
        optional :upnp, type: 'Boolean', desc: "Whether or not UPNP is supported by the model"
        optional :ptz, type: 'Boolean', desc: "Whether or not PTZ is supported by the model"
        optional :infrared, type: 'Boolean', desc: "Whether or not Infrared is supported by the model"
        optional :varifocal, type: 'Boolean', desc: "Whether or not Varifocal is supported by the model"
        optional :sd_card, type: 'Boolean', desc: "Whether or not SD Card is supported by the model"
        optional :audio_io, type: 'Boolean', desc: "Whether or not Audio Input/Output is supported by the model"
        optional :onvif, type: 'Boolean', desc: "Whether or not OnVif is supported by the model"
        optional :psia, type: 'Boolean', desc: "Whether or not PSIA is supported by the model"
        optional :discontinued, type: 'Boolean', desc: "Whether or not the vendor has Discontinued this model"
      end
      post do
        outcome = Actors::ModelCreate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present(Array(outcome.result), with: Presenters::Model)
      end

      #---------------------------------------------------------------------------
      # PATCH /v1/models/:id
      #---------------------------------------------------------------------------
      desc 'Updates full or partial data on your existing model', {
          entity: Evercam::Presenters::Model
        }
      params do
        requires :id, type: String, desc: "Unique identifier for the model"
        optional :name, type: String, desc: "Name of the model"
        optional :jpg_url, type: String, desc: "Snapshot url"
        optional :mjpg_url, type: String, desc: "Mjpg url"
        optional :mpeg4_url, type: String, desc: "MPEG4 url"
        optional :mobile_url, type: String, desc: "Mobile url"
        optional :h264_url, type: String, desc: "H264 url"
        optional :lowres_url, type: String, desc: "Low resolution url"
        optional :default_username, type: String, desc: "Default Username"
        optional :default_password, type: String, desc: "Default Password"
        optional :shape, type: String, desc: "Shape of the model"
        optional :resolution, type: String, desc: "Resolution(s) supported by model"
        optional :official_url, type: String, desc: "Official URL of model details"
        optional :audio_url, type: String, desc: "Audio stream URL of the model"
        optional :more_info, type: String, desc: "Additional information of the model"
        optional :poe, type: 'Boolean', desc: "Whether or not POE is supported by the model"
        optional :wifi, type: 'Boolean', desc: "Whether or not WiFi is supported by the model"
        optional :upnp, type: 'Boolean', desc: "Whether or not UPNP is supported by the model"
        optional :ptz, type: 'Boolean', desc: "Whether or not PTZ is supported by the model"
        optional :infrared, type: 'Boolean', desc: "Whether or not Infrared is supported by the model"
        optional :varifocal, type: 'Boolean', desc: "Whether or not Varifocal is supported by the model"
        optional :sd_card, type: 'Boolean', desc: "Whether or not SD Card is supported by the model"
        optional :audio_io, type: 'Boolean', desc: "Whether or not Audio Input/Output is supported by the model"
        optional :onvif, type: 'Boolean', desc: "Whether or not OnVif is supported by the model"
        optional :psia, type: 'Boolean', desc: "Whether or not PSIA is supported by the model"
        optional :discontinued, type: 'Boolean', desc: "Whether or not the vendor has Discontinued this model"
      end
      patch '/:id' do
        outcome = Actors::ModelUpdate.run(params)
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present(Array(outcome.result), with: Presenters::Model)
      end
    end
  end
end
