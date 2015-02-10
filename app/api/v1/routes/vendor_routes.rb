require_relative '../presenters/vendor_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    #---------------------------------------------------------------------------
    # GET /v1/vendors
    #---------------------------------------------------------------------------
    desc 'Returns all known IP hardware vendors', {
        entity: Evercam::Presenters::Vendor
      }
    params do
      optional :name, type: String, desc: "Name of the vendor (partial search)"
      optional :mac, type: String, desc: "Mac address of camera"
    end
    get '/vendors' do
      vendors = ::Vendor.eager(:vendor_models)
      vendors = vendors.where(exid: params[:id]) unless params.fetch(:id, nil).nil?
      vendors = vendors.where(Sequel.ilike(:name, "%#{params[:name]}%")) unless params.fetch(:name, nil).nil?
      vendors = vendors.where(%("known_macs" @> ARRAY[?]), params[:mac].upcase[0, 8]) unless params.fetch(:mac, nil).nil?
      present vendors.all, with: Presenters::Vendor, supported: true
    end

    #---------------------------------------------------------------------------
    # GET /v1/vendors/:id
    #---------------------------------------------------------------------------
    desc 'Returns available information for the specified vendor', {
        entity: Evercam::Presenters::Vendor
      }
    params do
      requires :id, type: String, desc: "Unique identifier for the vendor"
    end
    get '/vendors/:id' do
      vendor = Vendor.where(exid: params[:id]).first
      raise Evercam::NotFoundError.new("Unable to locate the '#{params[:id]}' vendor.",
          "vendor_not_found_error", params[:id]) if vendor.blank?
      present [vendor], with: Presenters::Vendor, supported: true
    end

    resource :vendors do
      before do
        authorize!
      end

      #---------------------------------------------------------------------------
      # POST /v1/vendors
      #---------------------------------------------------------------------------
      desc 'Create a new vendor', {
                                    entity: Evercam::Presenters::Vendor
                                }
      params do
        requires :id, type: String, desc: "Unique identifier for the vendor"
        requires :name, type: String, desc: "vendor name"
        optional :macs, type: String, desc: "Comma separated list of MAC's prefixes the vendor uses"
      end
      post do
        known_macs = ['']
        if params.include?(:macs) && params[:macs]
          known_macs = params[:macs].split(",").inject([]) { |list, entry| list << entry.strip }
        end
        outcome = Actors::VendorCreate.run(params.merge!(:known_macs => known_macs))
        unless outcome.success?
          raise OutcomeError, outcome.to_json
        end
        present Array(outcome.result), with: Presenters::Vendor, supported: true
      end
    end
  end
end

