require 'rack_helper'
require_app 'api/v1'

describe 'API routes/vendors' do

  let(:app) { Evercam::APIv1 }

  let!(:model0) { create(:vendor_model, name: VendorModel::DEFAULT, config: {username: 'aaa', password: 'xxx'}) }
  let!(:vendor0) { model0.vendor }
  let!(:model1) { create(:vendor_model, vendor: vendor0, name: 'v1', config: {jpg: '/aaa/snap', password: 'yyy'}) }
  let!(:vendor1) { create(:vendor) }

  let(:user) { create(:user) }
  let(:api_keys) { {api_id: user.api_id, api_key: user.api_key} }


  describe 'GET /vendors/search' do

    context 'for an authenticated request' do
      before(:each) { get('/vendors/search', api_keys) }

      let(:json) { last_response.json['vendors'] }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(json[0]).to have_keys('id', 'name', 'known_macs')
      end
    end
  end

  describe 'GET /vendors/search/:id' do

    context 'for an authenticated request' do
      before(:each) do
        params = api_keys.merge(:vendor_id => vendor0.exid)
        get('/vendors/search', params)
      end

      let(:json) { last_response.json['vendors'] }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(json[0]).to have_keys('id', 'name', 'known_macs')
      end

      it 'only returns supported vendors' do
        expect(json[0]['id']).to eq(vendor0.exid)
      end
    end
  end
end
