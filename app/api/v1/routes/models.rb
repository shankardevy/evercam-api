module Evercam
  class APIv1

    get '/models' do
      vendors = ::Vendor.all
      VendorPresenter.export(vendors, firmwares: false)
    end

    get '/models/:exid' do
      vendor = ::Vendor.by_exid(params[:exid])
      raise NotFoundError, 'vendor was not found' unless vendor
      VendorPresenter.export(vendor, firmwares: true)
    end

    get '/vendors' do
      vendors = Vendor.all
      VendorPresenter.export(vendors)
    end

    get '/vendors/:mac', requirements: { mac: Vendor::REGEX_MAC } do
      vendors = ::Vendor.by_mac(params[:mac][0,8])
      raise NotFoundError, 'mac address was not matched' if vendors.empty?
      VendorPresenter.export(vendors)
    end

  end
end

