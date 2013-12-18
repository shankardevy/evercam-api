require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:firmware0) { create(:firmware) }
  let!(:vendor0) { firmware0.vendor }
  let!(:vendor1) { create(:vendor) }

  describe 'GET /models' do

    before(:each) { get('/models') }

    let(:json) { last_response.json['vendors'] }

    it 'returns an OK status' do
      expect(last_response.status).to eq(200)
    end

    it 'returns the vendor data' do
      expect(json[0].keys).
        to eq(['id', 'name', 'known_macs', 'models'])
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
        expect(last_response.json['vendors'][0].keys).
          to eq(['id', 'name', 'known_macs', 'models'])
      end

    end

    context 'when the vendor is not supported' do
      it 'returns a NOT FOUND status' do
        expect(get("/models/#{vendor1.exid}").status).to eq(404)
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

      before(:each) { get("/models/#{vendor0.exid}/#{firmware0.known_models[0]}") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the model data' do
        expect(last_response.json['models'][0].keys).
          to eq(['vendor', 'name', 'known_models', 'defaults'])
      end

    end

    context 'when the model does not exist' do

      before(:each) { get("/models/#{vendor0.exid}/xxxx") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the default model data' do
        expect(last_response.json['models'][0]['known_models']).to eq(['*'])
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

