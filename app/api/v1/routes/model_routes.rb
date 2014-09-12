require_relative '../presenters/model_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 25

    before do
      authorize!
    end

    desc 'Returns set of known models for a supported camera vendor', {
      entity: Evercam::Presenters::Model
    }
    params do
      optional :id, type: String, desc: "Unique identifier for the model"
      optional :name, type: String, desc: "Name of the model (partial search)"
      optional :vendor_id, type: String, desc: "Unique identifier for the vendor"
      optional :limit, type: Integer, desc: "Number of results per page. Defaults to #{DEFAULT_LIMIT}."
      optional :page, type: Integer, desc: "Page number, starting from 0"
    end
    get '/models/search' do
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

  end
end

