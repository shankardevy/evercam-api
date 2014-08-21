require_relative '../presenters/model_presenter'
require_relative '../presenters/vendor_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    desc 'Returns set of known models for a supported camera vendor', {
      entity: Evercam::Presenters::Model
    }
    params do
      optional :id, type: String, desc: "Unique identifier for the model"
      optional :name, type: String, desc: "Name of the model"
      optional :vendor_id, type: String, desc: "Unique identifier for the vendor"
    end
    get '/models/search' do
      authreport!('models/vendor/get')
      v_id = params.fetch(:vendor, nil)
      vendor = nil
      unless v_id.nil?
        vendor = ::Vendor.by_exid(v_id).first
        raise NotFoundError, 'model vendor was not found' unless vendor
      end
      models = ::VendorModel.eager(:vendor)
      models = models.where(vendor_id: vendor.id) unless vendor.nil?
      models = models.where(Sequel.ilike(:name, "%#{params[:name]}%")) unless params.fetch(:name, nil).nil?
      models = models.where(exid: params[:id]) unless params.fetch(:id, nil).nil?
      present Array(models.all), with: Presenters::Model
    end


    desc 'Returns all known IP hardware vendors', {
      entity: Evercam::Presenters::Vendor
    }
    params do
      optional :id, type: String, desc: "Unique identifier for the vendor"
      optional :name, type: String, desc: "Name of the vendor"
      optional :mac, type: String, desc: "Mac address of camera"
    end
    get '/vendors/search' do
      authreport!('vendors/get')
      vendors = ::Vendor.eager(:vendor_models)
      vendors = vendors.where(exid: params[:id]) unless params.fetch(:id, nil).nil?
      vendors = vendors.where(Sequel.ilike(:name, "%#{params[:name]}%")) unless params.fetch(:name, nil).nil?
      vendors = vendors.where(%("known_macs" @> ARRAY[?]), params[:mac].upcase[0,8]) unless params.fetch(:mac, nil).nil?
      present vendors.all, with: Presenters::Vendor, supported: true
    end

  end
end

