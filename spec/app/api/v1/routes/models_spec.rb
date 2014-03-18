require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:model0) { create(:vendor_model, name: '*', config: {username:'aaa', password: 'xxx'}) }
  let!(:vendor0) { model0.vendor }
  let!(:model1) { create(:vendor_model, vendor: vendor0, name: 'v1', config: {jpg: '/aaa/snap', password: 'yyy'}) }
  let!(:vendor1) { create(:vendor) }

  describe 'GET /models' do

    before(:each) { get('/models') }

    let(:json) { last_response.json['vendors'] }

    it 'returns an OK status' do
      expect(last_response.status).to eq(200)
    end

    it 'returns the vendor data' do
      expect(json[0]).to have_keys(
        'id', 'name', 'known_macs', 'models')
    end

    it 'only returns supported vendors' do
      expect(json.map{ |v| v['id'] }).
        to eq([vendor0.exid])
    end

  end

  describe 'GET /models/{vendor}' do

    context 'when the vendor is supported' do

      before(:each) { get("/models/#{vendor0.exid}") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the vendor data' do
        expect(last_response.json['vendors'][0]).to have_keys(
          'id', 'name', 'known_macs', 'models')
      end

    end

    context 'when the vendor is not supported' do
      it 'returns a NOT FOUND status' do
        expect(get("/models/#{vendor1.exid}").status).to eq(404)
      end
    end

    context 'when the vendor is upper case' do
      it 'returns an OK status' do
        expect(get("/models/#{vendor0.exid.upcase}").status).to eq(200)
      end
    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/models/xxxx').status).to eq(404)
      end
    end

  end

  describe 'GET /models/{vendor}/{model}' do

    context 'when the model exists' do

      before(:each) { get("/models/#{vendor0.exid}/#{model1.name}") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(last_response.json['models'][0]).to have_keys(
          'vendor', 'name', 'known_models', 'defaults')
      end

      it 'returns correct defaults' do
        expect(last_response.json['models'][0]['defaults']).to eq({'jpg' => '/aaa/snap', 'username' => 'aaa', 'password' => 'yyy'})
      end

    end

    context 'when the vendor is upper case' do
      it 'returns an OK status' do
        expect(get("/models/#{vendor0.exid.upcase}/#{model1.name}").status).to eq(200)
      end
    end

    context 'when the model does not exist' do

      before(:each) { get("/models/#{vendor0.exid}/xxxx") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the default model data' do
        expect(last_response.json['models'][0]['name']).to eq('*')
      end

    end

  end

  describe 'GET /vendors' do

    before(:each) { get('/vendors') }

    it 'returns an OK status code' do
      expect(last_response.status).to eq(200)
    end

    it 'returns the data for each vendor' do
      expect(last_response.json['vendors'][0]).to have_keys(
        'id', 'name', 'known_macs', 'is_supported')
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
        expect(last_response.json['vendors'][0]).to have_keys(
          'id', 'name', 'known_macs', 'is_supported')
      end

    end

    context 'when the mac exists (all six octets)' do

      before(:each) { get("/vendors/#{vendor0.known_macs[0]}:Fa:Fb:Fc") }

      it 'returns an OK status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the data for the vendor' do
        expect(last_response.json['vendors'][0]).to have_keys(
          'id', 'name', 'known_macs', 'is_supported')
      end

    end

    context 'when the vendor does not exist' do
      it 'returns a NOT FOUND 404 status' do
        expect(get('/vendors/FF:FF:FF').status).to eq(404)
      end
    end

  end

end

