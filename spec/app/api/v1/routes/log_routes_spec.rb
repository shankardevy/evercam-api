require 'rack_helper'
require_app 'api/v1'

describe 'API routes/client', :focus=>true do
  let(:app) {
    Evercam::APIv1
  }

  describe 'GET /v1/cameras/:id/logs' do

    let!(:camera) {
      create(:camera)
    }

    let(:api_keys) { {api_id: camera.owner.api_id, api_key: camera.owner.api_key} }

    context 'when given a correct set of parameters' do
      it 'returns 401 when no api keys' do
        get("/cameras/#{camera.exid}/logs")
        expect(last_response.status).to eq(401)
      end

      it 'returns list of logs for given camera' do
        get("/cameras/#{camera.exid}/logs", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when log amount is big'
      before do
        #5.times do
        #  create(:camera_activity, camera: camera, access_token: nil)
        #end
      end

      it 'limit is working' do
        get("/cameras/#{camera.exid}/logs", api_keys)
        expect(last_response.status).to eq(200)
      end

      it 'pagination is working' do

      end

      it 'filters are working' do

      end
  end
end