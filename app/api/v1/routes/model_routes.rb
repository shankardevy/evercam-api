require_relative '../presenters/model_presenter'
require_relative '../presenters/vendor_presenter'

module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    desc 'Returns set of support supported camera vendors', {
      entity: Evercam::Presenters::Vendor
    }
    get '/models' do
      authreport!('models/get')
      vendors = ::Vendor.supported.eager(:firmwares).all
      present vendors, with: Presenters::Vendor, models: true
    end

    desc 'Returns set of known models for a supported camera vendor', {
      entity: Evercam::Presenters::Vendor
    }
    get '/models/:vendor' do
      authreport!('models/vendor/get')
      vendor = ::Vendor.supported.by_exid(params[:vendor]).first
      raise NotFoundError, 'model vendor was not found' unless vendor
      present Array(vendor), with: Presenters::Vendor, models: true
    end

    desc 'Returns data for a particular camera model', {
      entity: Evercam::Presenters::Model
    }
    get '/models/:vendor/:model' do
      authreport!('models/vendor/model/get')
      vendor = ::Vendor.supported.by_exid(params[:vendor]).first
      raise NotFoundError, 'model vendor was not found' unless vendor
      firmware = vendor.get_firmware_for(params[:model])
      present Array(firmware), with: Presenters::Model
    end

    desc 'Returns all known IP hardware vendors', {
      entity: Evercam::Presenters::Vendor
    }
    get '/vendors' do
      authreport!('vendors/get')
      vendors = ::Vendor.eager(:firmwares).all
      present vendors, with: Presenters::Vendor, supported: true
    end

    desc 'Returns all known IP hardware vendors filtered by MAC prefix', {
      entity: Evercam::Presenters::Vendor
    }
    get '/vendors/:mac', requirements: { mac: Vendor::REGEX_MAC } do
      authreport!('vendors/mac/get')
      vendors = ::Vendor.by_mac(params[:mac][0,8]).eager(:firmwares).all
      raise NotFoundError, 'mac address was not matched' if vendors.empty?
      present vendors, with: Presenters::Vendor, supported: true
    end

  end
end

