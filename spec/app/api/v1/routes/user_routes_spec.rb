require 'rack_helper'
require_app 'api/v1'

describe 'API routes/users' do

  let(:app) { Evercam::APIv1 }

  let(:params) do
    {
      forename: 'Garrett',
      lastname: 'Heaver',
      username: 'garrettheaver',
      email: 'garrett@evercam.io',
      country: create(:country).iso3166_a2
    }
  end

  describe 'POST /users' do

    context 'when the params are valid' do
      it 'creates the user and returns the json' do
        post('/users', params)

        expect(last_response.status).to eq(201)
        response0 = last_response.json['users'][0]

        expect(response0).to have_keys(
          'id', 'forename', 'lastname', 'username', 'email',
          'country', 'created_at', 'updated_at', 'confirmed_at')
      end
    end

    context 'when the username or email already exists' do
      it 'returns a 400 BAD Request status' do
        create(:user, username: 'xxxx')
        post('/users', params.merge(username: 'xxxx'))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when the country code does not exist' do
      it 'returns a 400 BAD Request status' do
        post('/users', params.merge(country: 'xx'))
        expect(last_response.status).to eq(400)
      end
    end

  end

  describe 'GET /users/{username}/cameras' do

    let!(:user0) { create(:user) }
    let!(:camera0) { create(:camera, owner: user0, is_public: true) }
    let!(:camera1) { create(:camera, owner: user0, is_public: false) }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/users/xxxx/cameras').status).to eq(404)
      end
    end

    context 'when the user does exist' do
      it 'returns an OK status' do
        expect(get("/users/#{user0.username}/cameras").status).to eq(200)
      end
    end

    context 'with no authentication information' do

      before(:each) { get("/users/#{user0.username}/cameras") }

      it 'only returns public cameras' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera0.exid])
      end

    end

    context 'when the authenticated user is the owner' do

      let(:auth) { env_for(session: { user: user0.id }) }

      before(:each) { get("/users/#{user0.username}/cameras", {}, auth) }

      it 'only returns public and private cameras' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera0.exid, camera1.exid])
      end

    end

  end

  describe 'DELETE /users/:id', :focus => true do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:auth) { env_for(session: { user: user0.id }) }

    context 'when the params are valid' do
      it 'deletes the user' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        delete("/users/#{user0.username}", {}, auth)

        expect(last_response.status).to eq(200)
        expect(::User.by_login(user0.username)).to eq(nil)

      end
    end

    context 'when no valid auth' do
      it 'returns 401' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('zzz:aaa')}" }
        delete("/users/#{user0.username}", {}, auth)

        expect(last_response.status).to eq(401)

      end
    end

    context 'when no auth' do
      it 'returns 401' do
        delete("/users/#{user0.username}")

        expect(last_response.status).to eq(401)

      end
    end

    context 'when the username doesnt exists' do
      it 'returns a 404 not found status' do
        delete('/users/notexistingone')
        expect(last_response.status).to eq(404)
      end
    end

  end
end

