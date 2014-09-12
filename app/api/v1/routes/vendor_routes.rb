require_relative '../presenters/vendor_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    before do
      authorize!
    end

    desc 'Returns all known IP hardware vendors', {
        entity: Evercam::Presenters::Vendor
    }
    params do
      optional :id, type: String, desc: "Unique identifier for the vendor"
      optional :name, type: String, desc: "Name of the vendor (partial search)"
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

