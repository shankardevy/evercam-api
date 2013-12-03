module Evercam
  class APIv1

    get '/vendors' do
      vendors = ::Vendor.all
      VendorPresenter.export(vendors, firmwares: false)
    end

    get '/vendors/:mac', requirements: { mac: /([0-9A-F]{2}[:-]){2,5}([0-9A-F]{2})/i } do
      vendors = ::Vendor.by_mac(params[:mac][0,8])
      raise NotFoundError, 'mac address was not matched' if vendors.empty?
      VendorPresenter.export(vendors, firmwares: true)
    end

    get '/vendors/:exid' do
      vendor = ::Vendor.by_exid(params[:exid])
      raise NotFoundError, 'vendor was not found' unless vendor
      VendorPresenter.export(vendor, firmwares: true)
    end

  end
end

