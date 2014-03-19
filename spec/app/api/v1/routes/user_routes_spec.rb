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

  describe 'GET /testusername' do

    let!(:user0) { create(:user, username: 'xxxx', email: 'xxxx@gmail.com') }

    context 'when username is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.username}", {})

        expect(last_response.status).to eq(400)
      end
    end

    context 'when username is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique", {})
        expect(last_response.status).to eq(200)
      end
    end

    context 'when email is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.email}", {})

        expect(last_response.status).to eq(400)
      end
    end

    context 'when email is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique@gmail.com", {})
        expect(last_response.status).to eq(200)
      end
    end

  end
  describe 'POST /users' do

    context 'when the params are valid' do
      it 'creates the user and returns the json' do
        VCR.use_cassette('API_users/account_creation') do
          post('/users', params)

          expect(last_response.status).to eq(201)
          response0 = last_response.json['users'][0]

          expect(response0).to have_keys(
            'id', 'forename', 'lastname', 'username', 'email',
            'country', 'created_at', 'updated_at', 'confirmed_at')
        end
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

    context 'when the country code is in capital letters' do
      it 'returns a 400 BAD Request status' do
        VCR.use_cassette('API_users/account_creation') do
          params[:country].upcase!
          post('/users', params)
          expect(last_response.status).to eq(201)
        end
      end
    end

  end

  describe 'GET /users/{username}' do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/users/notexisitngid').status).to eq(404)
      end
    end

    context 'with no authentication information' do

      before(:each) { get("/users/#{user0.username}") }

      it 'returns 401' do
        expect(last_response.status).to eq(401)
      end

    end

    context 'when the authenticated user is the owner' do

      let(:auth) { env_for(session: { user: user0.id }) }

      before(:each) {
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        get("/users/#{user0.username}", {}, auth)
      }

      it 'returns user data' do
        expect(last_response.status).to eq(200)
        expect(last_response.json['users'].map{ |s| s['id'] }).
          to eq([user0.username])
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

  describe 'DELETE /users/:id' do

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

  describe 'PATCH /users/:id' do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:auth) { env_for(session: { user: user0.id }) }

    context 'when no params' do

      before do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        patch("/users/#{user0.username}", {}, auth)
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns same user' do
        expect(last_response.status).to eq(200)
        user = User.by_login(user0.username)
        expect(user.forename).to eq(user0.forename)
        expect(user.lastname).to eq(user0.lastname)
        expect(user.email).to eq(user0.email)
        expect(user.country).to eq(user0.country)
      end
    end

    context 'when valid params' do

      before do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        patch("/users/#{user0.username}", params.merge(email: 'gh@evercam.io'), auth)
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'updates user in the system' do
        user = User.by_login(user0.username)
        expect(user.forename).to eq(params[:forename])
        expect(user.lastname).to eq(params[:lastname])
        expect(user.email).to eq('gh@evercam.io')
        expect(user.country.iso3166_a2).to eq(params[:country])
      end

      it 'returns the updated user' do
        expect(last_response.json['users'].map{ |s| s['id'] }).
          to eq([user0.username])
      end
    end




    context 'when no valid auth' do
      it 'returns 401' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('zzz:aaa')}" }
        patch("/users/#{user0.username}", params, auth)

        expect(last_response.status).to eq(401)

      end
    end

    context 'when no auth' do
      it 'returns 401' do
        patch("/users/#{user0.username}", params)

        expect(last_response.status).to eq(401)

      end
    end

    context 'when the username doesnt exists' do
      it 'returns a 404 not found status' do
        patch('/users/notexistingone')
        expect(last_response.status).to eq(404)
      end
    end

  end

end

