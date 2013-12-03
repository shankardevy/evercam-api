require 'rack_helper'
require_app 'api/v1'

describe 'API routes/vendors' do

  let(:app) { Evercam::APIv1 }

  describe 'GET /vendors' do
    it 'returns the set of all known vendors' do
      create(:vendor)
      get '/vendors'

      expect(last_response.status).to eq(200)
      response0 = last_response.json['vendors'][0]

      expect(response0.keys).
        to eq(['id', 'name', 'known_macs'])
    end
  end

  describe 'GET /vendors/{vendor}' do

    context 'when the vendor exists' do
      it 'returns the data for the vendor' do
        firmware0 = create(:firmware)
        vendor0 = firmware0.vendor

        get "/vendors/#{vendor0.exid}"

        expect(last_response.status).to eq(200)
        response0 = last_response.json['vendors'][0]

        expect(response0.keys).
          to eq(['id', 'name', 'known_macs', 'firmwares'])
      end
    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        get '/vendors/xxxx'
        expect(last_response.status).to eq(404)
      end
    end

  end

  describe 'GET /vendors/{mac}' do

    let(:known_macs) do
      firmware0 = create(:firmware)
      firmware0.vendor.known_macs
    end

    context 'when the mac exists (first three octets)' do
      it 'returns the data for the vendor' do
        get "/vendors/#{known_macs[0][0,8]}"

        expect(last_response.status).to eq(200)
        response0 = last_response.json['vendors'][0]

        expect(response0.keys).
          to eq(['id', 'name', 'known_macs', 'firmwares'])
      end
    end

    context 'when the mac exists (all six octets)' do
      it 'returns the data for the vendor' do
        get "/vendors/#{known_macs[0]}:Fa:Fb:Fc"

        expect(last_response.status).to eq(200)
        response0 = last_response.json['vendors'][0]

        expect(response0.keys).
          to eq(['id', 'name', 'known_macs', 'firmwares'])
      end
    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        get '/vendors/FF:FF:FF'
        expect(last_response.status).to eq(404)
      end
    end

  end

end

