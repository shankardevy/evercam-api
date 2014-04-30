require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:model0) { create(:vendor_model, name: VendorModel::DEFAULT, config: {username:'aaa', password: 'xxx'}) }
  let!(:vendor0) { model0.vendor }
  let!(:model1) { create(:vendor_model, vendor: vendor0, name: 'v1', config: {jpg: '/aaa/snap', password: 'yyy'}) }
  let!(:vendor1) { create(:vendor) }

  let(:user) { create(:user) }
  let(:api_keys) { {api_id: user.api_id, api_key: user.api_key} }

  describe 'GET /models' do

    context 'for an authenticated request' do
      before(:each) { get('/models', api_keys) }

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

    context 'for an unauthenticated request' do
      before(:each) { get('/models') }

      let(:json) { last_response.json['vendors'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'GET /models/{vendor}' do

    context 'for an authenticate request' do
      context 'when the vendor is supported' do
        before(:each) { get("/models/#{vendor0.exid}", api_keys) }

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
          expect(get("/models/#{vendor1.exid}", api_keys).status).to eq(404)
        end
      end

      context 'when the vendor is upper case' do
        it 'returns an OK status' do
          expect(get("/models/#{vendor0.exid.upcase}", api_keys).status).to eq(200)
        end
      end

      context 'when the vendor does not exist' do
        it 'returns a NOT FOUND status' do
          expect(get('/models/xxxx', api_keys).status).to eq(404)
        end
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get("/models/#{vendor0.exid}") }

      let(:json) { last_response.json['vendors'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'GET /models/{vendor}/{model}' do
    context 'for an authenticated request' do
      context 'when the model exists' do
        before(:each) { get("/models/#{vendor0.exid}/#{model1.name}", api_keys) }

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
          expect(get("/models/#{vendor0.exid.upcase}/#{model1.name}", api_keys).status).to eq(200)
        end
      end

      context 'when the model does not exist' do
        before(:each) { get("/models/#{vendor0.exid}/xxxx", api_keys) }

        it 'returns an OK status' do
          expect(last_response.status).to eq(200)
        end

        it 'returns the default model data' do
          expect(last_response.json['models'][0]['name']).to eq(VendorModel::DEFAULT)
        end
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get("/models/#{vendor0.exid}/#{model1.name}") }

      let(:json) { last_response.json['vendors'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'GET /vendors' do
    context 'for an authenticated request' do
      before(:each) { get('/vendors', api_keys) }

      it 'returns an OK status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the data for each vendor' do
        expect(last_response.json['vendors'][0]).to have_keys(
          'id', 'name', 'known_macs', 'is_supported')
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get("/vendors") }

      let(:json) { last_response.json['vendors'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'GET /vendors/{mac}' do
    context 'for an authenticated request' do
      let(:known_macs) { vendor0.known_macs }

      context 'when the mac exists (first three octets)' do

        before(:each) { get("/vendors/#{vendor0.known_macs[0]}", api_keys) }

        it 'returns an OK status code' do
          expect(last_response.status).to eq(200)
        end

        it 'returns the data for the vendor' do
          expect(last_response.json['vendors'][0]).to have_keys(
            'id', 'name', 'known_macs', 'is_supported')
        end

      end

      context 'when the mac exists (all six octets)' do

        before(:each) { get("/vendors/#{vendor0.known_macs[0]}:Fa:Fb:Fc", api_keys) }

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
          expect(get('/vendors/FF:FF:FF', api_keys).status).to eq(404)
        end
      end
    end

    context 'for an unauthenticated request' do
      before(:each) { get("/vendors/#{vendor0.known_macs[0]}") }

      let(:json) { last_response.json['vendors'] }

      it 'returns an unauthenticated error' do
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

end

