module Evercam
  class V1ModelRoutes < Grape::API

    include WebErrors

    get '/models' do
      vendors = ::Vendor.supported.eager(:firmwares).all
      VendorPresenter.export(vendors, models: true)
    end

    get '/models/:vendor' do
      vendor = ::Vendor.supported.by_exid(params[:vendor]).first
      raise NotFoundError, 'model vendor was not found' unless vendor
      VendorPresenter.export(vendor, models: true)
    end

    get '/models/:vendor/:model' do
      vendor = ::Vendor.supported.by_exid(params[:vendor]).first
      raise NotFoundError, 'model vendor was not found' unless vendor
      firmware = vendor.get_firmware_for(params[:model])
      ModelPresenter.export(firmware)
    end

    get '/vendors' do
      vendors = ::Vendor.eager(:firmwares).all
      VendorPresenter.export(vendors, supported: true)
    end

    get '/vendors/:mac', requirements: { mac: Vendor::REGEX_MAC } do
      vendors = ::Vendor.by_mac(params[:mac][0,8]).eager(:firmwares).all
      raise NotFoundError, 'mac address was not matched' if vendors.empty?
      VendorPresenter.export(vendors, supported: true)
    end

  end
end

