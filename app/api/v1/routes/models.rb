module Evercam
  class APIv1

    get '/models' do
      vendors = ::Vendor.supported.eager(:firmwares).all
      VendorPresenter.export(vendors, models: true)
    end

    get '/models/:exid' do
      vendor = ::Vendor.supported.by_exid(params[:exid]).first
      raise NotFoundError, 'vendor was not found' unless vendor
      VendorPresenter.export(vendor, models: true)
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

