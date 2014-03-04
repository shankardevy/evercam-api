require 'rack_helper'
require_app 'web/app'
require_lib 'actors'

describe 'WebApp routes/users_router' do

  let(:app) { Evercam::WebApp }

  let(:user0) { create(:user, username: 'tjama') }
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

  describe 'GET /users/{username}/dev' do

    context 'when the user does not exist' do
      it 'returns a 404 status' do
        get('/users/xxxx/dev')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the user does exist, but we are not authenticated' do
      it 'returns Not Authorized' do
        get("/users/#{user0.username}/dev")
        expect(last_response.status).to eq(401)
      end
    end

    context 'when the user does exist and we are authenticated' do
      VCR.use_cassette('Web_users/threescale_keys') do
        it 'returns user profile' do
          get("/users/#{user0.username}/dev", {}, auth)
          expect(last_response.status).to eq(200)
        end
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

  describe 'GET /user' do
    context 'when a user is not logged in' do
      it "returns a not found" do
        get('/user')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when a user is logged in' do
      it "returns details for the currently logged in user" do
        get("/user", {}, auth)
        expect(last_response.status).to eq(200)

        data = JSON.parse(last_response.body)
        expect(data.include?("id")).to eq(true)
        expect(data.include?("forename")).to eq(true)
        expect(data.include?("lastname")).to eq(true)
        expect(data.include?("username")).to eq(true)
        expect(data.include?("email")).to eq(true)
        expect(data.include?("country")).to eq(true)
        expect(data.include?("created_at")).to eq(true)
        expect(data.include?("updated_at")).to eq(true)

        expect(data["id"]).to eq(user0.username)
        expect(data["forename"]).to eq(user0.forename)
        expect(data["lastname"]).to eq(user0.lastname)
        expect(data["username"]).to eq(user0.username)
        expect(data["email"]).to eq(user0.email)
        expect(data["country"]).to eq(user0.country.iso3166_a2)
        expect(data["created_at"]).to eq(user0.created_at.to_i)
        expect(data["updated_at"]).to eq(user0.updated_at.to_i)
      end
    end
  end

end

