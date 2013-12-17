require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:vendor0) { create(:vendor) }

  describe 'GET /models' do
    it 'returns the set of all known vendors' do
      get '/models'

      expect(last_response.status).to eq(200)
      response0 = last_response.json['vendors'][0]

      expect(response0.keys).
        to eq(['id', 'name', 'known_macs'])
    end
  end

  describe 'GET /models/{vendor}' do

    context 'when the vendor exists' do
      it 'returns the data for the vendor' do
        firmware0 = create(:firmware)
        vendor0 = firmware0.vendor

        get "/models/#{vendor0.exid}"

        expect(last_response.status).to eq(200)
        response0 = last_response.json['vendors'][0]

        expect(response0.keys).
          to eq(['id', 'name', 'known_macs', 'firmwares'])
      end
    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        get '/models/xxxx'
        expect(last_response.status).to eq(404)
      end
    end

  end

  describe 'GET /vendors' do

    before(:each) { get('/vendors') }

    it 'returns an OK status code' do
      expect(last_response.status).to eq(200)
    end

    it 'returns the data for each vendor' do
      expect(last_response.json['vendors'][0].keys).
        to eq(['id', 'name', 'known_macs', 'is_supported'])
    end

  end

  describe 'GET /vendors/{mac}' do

    let(:known_macs) { vendor0.known_macs }

    context 'when the mac exists (first three octets)' do

      before(:each) { get("/vendors/#{vendor0.known_macs[0]}") }

      it 'returns an OK status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the data for the vendor' do
        expect(last_response.json['vendors'][0].keys).
          to eq(['id', 'name', 'known_macs', 'is_supported'])
      end

    end

    context 'when the mac exists (all six octets)' do

      before(:each) { get("/vendors/#{vendor0.known_macs[0]}:Fa:Fb:Fc") }

      it 'returns an OK status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the data for the vendor' do
        expect(last_response.json['vendors'][0].keys).
          to eq(['id', 'name', 'known_macs', 'is_supported'])
      end

    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        expect(get('/vendors/FF:FF:FF').status).to eq(404)
      end
    end

  end

end

