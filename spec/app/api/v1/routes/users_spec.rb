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

        expect(response0.keys).
          to eq(['id', 'forename', 'lastname', 'username', 'email',
                 'country', 'created_at', 'updated_at', 'confirmed_at'])
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

  describe 'GET /users/{username}/streams' do

    let!(:user0) { create(:user) }
    let!(:stream0) { create(:stream, owner: user0, is_public: true) }
    let!(:stream1) { create(:stream, owner: user0, is_public: false) }

    context 'with no authentication information' do

      before(:each) { get("/users/#{user0.username}/streams") }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the stream data' do
        expect(last_response.json['streams'][0]).to have_keys(
          'id', 'owner', 'created_at', 'updated_at',
          'is_public', 'endpoints', 'snapshots', 'auth')
      end

      it 'only returns public streams' do
        expect(last_response.json['streams'].map{ |s| s['id'] }).
          to eq([stream0.name])
      end

    end

    context 'when the authenticated user is the owner' do

      let(:auth) { env_for(session: { user: user0.id }) }

      before(:each) { get("/users/#{user0.username}/streams", {}, auth) }

      it 'returns an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the stream data' do
        expect(last_response.json['streams'][0]).to have_keys(
          'id', 'owner', 'created_at', 'updated_at',
          'is_public', 'endpoints', 'snapshots', 'auth')
      end

      it 'only returns public and private streams' do
        expect(last_response.json['streams'].map{ |s| s['id'] }).
          to eq([stream0.name, stream1.name])
      end

    end

  end
end

