require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:model0) { create(:vendor_model, name: VendorModel::DEFAULT, config: {username: 'aaa', password: 'xxx'}) }
  let!(:vendor0) { model0.vendor }
  let!(:model1) { create(:vendor_model, vendor: vendor0, name: 'v1', config: {jpg: '/aaa/snap', password: 'yyy'}) }
  let!(:vendor1) { create(:vendor) }

  let(:user) { create(:user) }
  let(:api_keys) { {api_id: user.api_id, api_key: user.api_key} }


  describe 'GET /models/search' do

    context 'for an authenticated request' do
      before(:each) { get('/models/search', api_keys) }

      let(:json) { last_response.json['models'] }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(json[0]).to have_keys('id', 'name', 'vendor_id', 'defaults')
      end

      it 'only returns supported models' do
        expect(json.map { |v| v['id'] }).
            to eq([model0.exid, model1.exid])
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get('/models/search') }

      let(:json) { last_response.json['models'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end
  end

  describe 'GET /models/search/:id' do

    context 'for an authenticated request' do
      before(:each) do
        params = api_keys.merge(:vendor_id => vendor0.exid)
        get('/models/search', params)
      end

      let(:json) { last_response.json['models'] }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(json[0]).to have_keys('id', 'name', 'vendor_id', 'defaults')
      end

      it 'only returns supported models' do
        expect(json.map { |v| v['vendor_id'] }.uniq).
            to eq([vendor0.exid])
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get('/models/search') }

      let(:json) { last_response.json['models'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end
  end


end

