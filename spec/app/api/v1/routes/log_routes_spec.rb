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
        now = Time.now
        60.times do |i|
          create(:camera_activity, camera: camera, access_token: nil, done_at: now + i)
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
    end
  end
end