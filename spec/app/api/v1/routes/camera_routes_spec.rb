require 'rack_helper'
require_app 'api/v1'

describe 'API routes/cameras' do

  let(:app) { Evercam::APIv1 }

  describe 'GET /cameras/:id' do

    let(:camera) { create(:camera, is_public: true) }

    context 'when the camera does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/cameras/xxxx').status).to eq(404)
      end
    end

    context 'when the camera is public' do
      it 'returns the camera data' do
        response = get("/cameras/#{camera.exid}")
        expect(response.status).to eq(200)
      end
    end

    context 'when the camera is private' do

      let(:camera) { create(:camera, is_public: false) }

      context 'when the request is unauthenticated' do
        it 'returns an UNAUTHORIZED status' do
          expect(get("/cameras/#{camera.exid}").status).to eq(401)
        end
      end

      context 'when the request is unauthorized' do
        it 'returns a FORBIDDEN status' do
          create(:user, username: 'xxxx', password: 'yyyy')
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/cameras/#{camera.exid}", {}, env).status).to eq(403)
        end
      end

      context 'when the request is authorized' do
        it 'returns the camera data' do
          camera.update(owner: create(:user, username: 'xxxx', password: 'yyyy'))
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/cameras/#{camera.exid}", {}, env).status).to eq(200)
        end
      end

    end

    it 'returns all the camera data keys' do
      response = get("/cameras/#{camera.exid}")
      expect(response.json['cameras'][0]).to have_keys(
        'id', 'name', 'owner', 'created_at', 'updated_at',
        'polled_at', 'is_public', 'is_online', 'last_online_at',
        'endpoints', 'vendor', 'model', 'timezone', 'snapshots', 'auth')
    end

    it 'returns the camera make and model information when available' do
      model = create(:firmware)
      camera.update(firmware: model)

      response = get("/cameras/#{camera.exid}")
      data = response.json['cameras'][0]

      expect(data['vendor']).to eq(model.vendor.exid)
      expect(data['model']).to eq(model.name)
    end

  end

  describe 'POST /cameras' do

    let(:auth) { env_for(session: { user: create(:user).id }) }

    let(:params) {
      {
        id: 'my-new-camera',
        name: "Garrett's Super New Camera",
        endpoints: ['http://localhost:1234'],
        is_public: true
      }.merge(
        build(:camera).config
      )
    }

    context 'when the params are valid' do

      before(:each) do
        post('/cameras', params, auth)
      end

      it 'returns a CREATED status' do
        expect(last_response.status).to eq(201)
      end

      it 'creates a new camera in the system' do
        expect(Camera.first.exid).
          to eq(params[:id])
      end

      it 'returns the new camera' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([Camera.first.exid])
      end

    end

    context 'when is_public is null' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(is_public: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when :endpoints key is missing' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(endpoints: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHROZIED status' do
        expect(post('/cameras', params).status).to eq(401)
      end
    end

  end

  describe 'PUT /cameras', :focus => true do

    let(:camera) { create(:camera, is_public: true) }
    let(:auth) { env_for(session: { user: create(:user).id }) }

    let(:params) {
      {
        name: "Garrett's Super New Camera v2",
        endpoints: ['http://localhost:4321'],
        is_public: false
      }
    }

    context 'when the params are valid' do

      before(:each) do
        put("/cameras/#{camera.exid}", params, auth)
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'updates camera in the system' do
        expect(Camera.by_exid(camera.exid).is_public).
          to eq(false)
        expect(Camera.by_exid(camera.exid).name).
          to eq("Garrett's Super New Camera v2")
        expect(Camera.by_exid(camera.exid).endpoints.length).
          to eq(1)
        expect(Camera.by_exid(camera.exid).endpoints[0][:port]).
          to eq(4321)
      end

      it 'returns the updated camera' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera.exid])
      end

    end

    context 'when params are empty' do
      it 'returns a OK status' do
        put("/cameras/#{camera.exid}", params.clear, auth)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHROZIED status' do
        expect(put("/cameras/#{camera.exid}", params).status).to eq(401)
      end
    end

  end

end

