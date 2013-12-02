require 'rack_helper'
require_app 'api/v1'

describe 'API routes/vendors' do

  let(:app) { Evercam::APIv1 }

  describe 'GET /vendors' do
    it 'returns the set of all known vendors' do
      create(:vendor)
      get '/vendors'

      expect(last_response.status).to eq(200)
      expect(last_response.json.keys).
        to eq(['vendors'])
    end
  end

  describe 'GET /vendors/{vendor}' do

    context 'when the vendor exists' do
      it 'returns the data for the vendor' do
        vendor0 = create(:vendor)
        get "/vendors/#{vendor0.exid}"

        expect(last_response.status).to eq(200)
        expect(last_response.json.keys).
          to eq(['vendors'])
      end
    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        get '/vendors/xxxx'
        expect(last_response.status).to eq(404)
      end
    end

  end

end

