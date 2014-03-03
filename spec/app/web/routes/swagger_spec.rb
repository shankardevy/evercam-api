require 'rack_helper'
require_app 'web/app'
require_app 'api/v1'

describe 'Just test swagger for 200' do

  let(:app) { Evercam::APIv1 }

  context 'when swagger endpoints are hit' do
    it 'returns 200' do
      get("/swagger")
      expect(last_response.status).to eq(200)

      get("/swagger/users")
      expect(last_response.status).to eq(200)
      get("/swagger/models")
      expect(last_response.status).to eq(200)
      get("/swagger/cameras")
      expect(last_response.status).to eq(200)
      get("/swagger/vendors")
      expect(last_response.status).to eq(200)
    end
  end

end