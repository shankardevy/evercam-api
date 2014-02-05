require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/users_router' do

  let(:app) { Evercam::WebApp }

  let(:user0) { create(:user) }
  let(:camera0) { create(:camera, owner: user0) }

  describe 'GET /users/{username}' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist' do
      it 'returns the user dashboard' do
        get("/users/#{user0.username}")
        expect(last_response.status).to eq(200)
      end
    end

    end

  describe 'GET /users/{username}/cameras/{camera}' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx/cameras/yyyy')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist and camera doesnt' do
      it 'returns a 404 status' do
        get("/users/#{user0.username}/cameras/yyyy")
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist and camera does exist' do
      it 'returns the camera dashboard' do
        get("/users/#{user0.username}/cameras/#{camera0.exid}")
        expect(last_response.status).to eq(200)
      end
    end

  end

end

