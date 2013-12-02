module Evercam
  class APIv1

    get '/vendors' do
      vendors = Vendor.all

      data = vendors.map do |v|
        {
          id: v.exid,
          name: v.name,
          known_macs: v.known_macs
        }
      end

      { vendors: data }
    end

    get '/vendors/:exid' do
      vendor = ::Vendor.by_exid(params[:exid])
      raise NotFoundError, 'vendor was not found' unless vendor

      {
        vendors: [{
          id: vendor.exid,
          name: vendor.name,
          known_macs: vendor.known_macs
        }]
      }
    end

  end
end
