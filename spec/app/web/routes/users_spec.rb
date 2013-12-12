require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/users' do

  let(:app) { Evercam::WebApp }

  let(:user0) { create(:user) }

  describe 'GET /users/{username}' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist' do
      it 'returns a placeholder for the user dashboard' do
        get("/users/#{user0.username}")
        expect(last_response.status).to eq(200)
      end
    end

  end

end

