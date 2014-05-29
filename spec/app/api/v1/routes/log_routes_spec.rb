require 'rack_helper'
require_app 'api/v1'

describe 'API routes/client' do
  let(:app) {
    Evercam::APIv1
  }

  describe 'GET /v1/cameras/:id/logs' do

    let!(:camera) {
      create(:camera)
    }

    let(:api_keys) { {api_id: camera.owner.api_id, api_key: camera.owner.api_key} }

    context 'when some parrameters are missing or incorrect' do
      it 'returns 401 when no api keys' do
        get("/cameras/#{camera.exid}/logs")
        expect(last_response.status).to eq(401)
      end

      it 'returns 400 when from > to' do
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({from: 100, to: 50}))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when given a correct set of parameters' do
      it 'returns list of logs for given camera' do
        get("/cameras/#{camera.exid}/logs", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when log amount is big' do
      before do
        create(:camera_activity, camera: camera, action: 'aaa')
        time = Time.at(100)
        60.times do |i|
          create(:camera_activity, camera: camera, access_token: nil, done_at: time - i)
        end
      end

      it 'limit is working' do
        get("/cameras/#{camera.exid}/logs", api_keys)
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(50)
      end

      it 'pagination is working' do
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({page: 1}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(11)
      end

      it 'filters are working' do
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({types: 'aaa'}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(1)
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({types: 'aaa, Test', limit: 999}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(61)
      end

      it 'date range is working' do
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({from: 90}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(12)
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({from: 50, to: 60}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(11)
        get("/cameras/#{camera.exid}/logs", api_keys.merge!({from: nil, to: 70, objects: true}))
        expect(last_response.status).to eq(200)
        expect(last_response.json['logs'].length).to eq(30)
      end
    end
  end
end