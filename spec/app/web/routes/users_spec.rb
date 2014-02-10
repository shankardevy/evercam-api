require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/users_router' do

  let(:app) { Evercam::WebApp }

  let(:user0) { create(:user) }
  let(:camera0) { create(:camera, owner: user0) }
  let(:auth) { env_for(session: { user: user0.id }) }

  describe 'GET /users/{username}' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist, but we are not authenticated' do
      it 'returns the user dashboard with public cameras' do
        get("/users/#{user0.username}")
        expect(last_response.status).to eq(200)
      end
    end

    context 'when the user does exist and we are authenticated' do
      it 'returns the user dashboard with all  cameras' do
        get("/users/#{user0.username}", {}, auth)
        expect(last_response.status).to eq(200)
      end
    end

  end

  describe 'GET /users/{username}/profile' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx/profile')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist, but we are not authenticated' do
      it 'returns Not Authorized' do
        get("/users/#{user0.username}/profile")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the user does exist and we are authenticated' do
      it 'returns user profile' do
        get("/users/#{user0.username}/profile", {}, auth)
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

    context 'when the user does exist and camera doesnt, but we are not authenticated' do
      it 'returns a 401 status' do
        get("/users/#{user0.username}/cameras/yyyy")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the user does exist and camera doesnt and we are authenticated' do
      it 'returns a 404 status' do
        get("/users/#{user0.username}/cameras/yyyy", {}, auth)
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist and camera does exist, but we are not authenticated' do
      it 'returns Not Authorized' do
        get("/users/#{user0.username}/cameras/#{camera0.exid}")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the user does exist and camera does exist and we are authenticated' do
      it 'returns the camera dashboard' do
        get("/users/#{user0.username}/cameras/#{camera0.exid}", {}, auth)
        expect(last_response.status).to eq(200)
      end
    end

  end

end

