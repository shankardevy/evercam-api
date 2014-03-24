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

  let(:other_user) { create(:user) }
  let(:alt_keys) { {api_id: other_user.api_id, api_key: other_user.api_key} }

  before(:each) do
    body = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"\
           "<status>\n"\
           "  <authorized>true</authorized>\n"\
           "  <plan>Pay As You Go ($20 for 10,000 hits)</plan>\n"\
           "</status>"
    stub_request(:post, 'https://evercam-admin.3scale.net/admin/api/signup.xml').to_return(status: 200,
                                                                                           body: body,
                                                                                           headers: {})
  end

  describe 'GET /testusername' do

    let!(:user0) { create(:user, username: 'xxxx', email: 'xxxx@gmail.com') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when username is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.username}", api_keys)

        expect(last_response.status).to eq(400)
      end
    end

    context 'when username is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when email is already in use' do
      it 'returns 400 error ' do
        get("/testusername?username=#{user0.email}", api_keys)

        expect(last_response.status).to eq(400)
      end
    end

    context 'when email is not in use' do
      it 'returns a 200 OK status' do
        get("/testusername?username=unique@gmail.com", api_keys)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when not authenticated' do
      it 'returns an unauthenticated error' do
        get("/testusername?username=unique")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'POST /users' do

    let(:user) { create(:user) }
    let(:api_keys) { {api_id: user.api_id, api_key: user.api_key} }

    context 'when the params are valid' do
      it 'creates the user and returns the json' do
        VCR.use_cassette('API_users/account_creation') do
          post('/users', params.merge(api_keys))

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
        post('/users', params.merge(username: 'xxxx').merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when the country code does not exist' do
      it 'returns a 400 BAD Request status' do
        post('/users', params.merge(country: 'xx').merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when the country code is in capital letters' do
      it 'returns a 400 BAD Request status' do
        VCR.use_cassette('API_users/account_creation') do
          params[:country].upcase!
          post('/users', params.merge(api_keys))
          expect(last_response.status).to eq(201)
        end
      end
    end

    context 'when not authenticated' do
      it 'returns an unauthenticated error' do
        VCR.use_cassette('API_users/account_creation') do
          post('/users', params)
        end
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

  end

  describe 'GET /users/{username}' do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/users/notexisitngid', api_keys).status).to eq(404)
      end
    end

    context 'with no authentication information' do

      before(:each) { get("/users/#{user0.username}") }

      it 'returns 401' do
        expect(last_response.status).to eq(401)
      end

    end

    context 'when the authenticated user is the owner' do
      before(:each) {
        get("/users/#{user0.username}", api_keys)
      }

      it 'returns user data' do
        data = last_response.json
        expect(data).not_to be_nil
        expect(data.include?("users")).to eq(true)
        expect(data["users"].map {|s| s['id']}).to eq([user0.username])
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        get("/users/#{user0.username}", credentials)
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

  describe 'GET /users/{username}/cameras' do

    let!(:user0) { create(:user) }
    let!(:camera0) { create(:camera, owner: user0, is_public: true) }
    let!(:camera1) { create(:camera, owner: user0, is_public: false) }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the user does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/users/xxxx/cameras', api_keys).status).to eq(404)
      end
    end

    context 'when the user does exist' do
      it 'returns an OK status' do
        expect(get("/users/#{user0.username}/cameras", api_keys).status).to eq(200)
      end
    end

    context 'with no authentication information' do

      before(:each) { get("/users/#{user0.username}/cameras") }

      it 'only returns public cameras' do
        content = last_response.json
        expect(content).not_to be_nil
        expect(content.include?("cameras")).to eq(true)
        expect(content["cameras"].map {|s| s['id']}).to eq([camera0.exid])
      end

    end

    context 'when the authenticated user is the owner' do

      before(:each) { get("/users/#{user0.username}/cameras", api_keys) }

      it 'only returns public and private cameras' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera0.exid, camera1.exid])
      end

    end

  end

  describe 'DELETE /users/:id' do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:auth) { env_for(session: { user: user0.id }) }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when the params are valid' do
      it 'deletes the user' do
        delete("/users/#{user0.username}", api_keys)

        expect(last_response.status).to eq(200)
        expect(::User.by_login(user0.username)).to eq(nil)

      end
    end

    context 'when no valid auth' do
      it 'returns 401' do
        delete("/users/#{user0.username}")
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
        delete('/users/notexistingone', api_keys)
        expect(last_response.status).to eq(404)
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        get("/users/#{user0.username}", credentials)
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

  describe 'PATCH /users/:id' do

    let!(:user0) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:api_keys) { {api_id: user0.api_id, api_key: user0.api_key} }

    context 'when no params' do

      before do
        patch("/users/#{user0.username}", api_keys)
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
        patch("/users/#{user0.username}", params.merge(email: 'gh@evercam.io').merge(api_keys))
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
        patch("/users/#{user0.username}", params.merge(api_id: 'blah', api_key: 'blah'))
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
        patch('/users/notexistingone', api_keys)
        expect(last_response.status).to eq(404)
      end
    end

    context 'when not authorized' do
      let(:different_user) { create(:user) }
      let(:credentials) { {api_id: different_user.api_id, api_key: different_user.api_key} }

      it 'returns an unauthorized error' do
        patch("/users/#{user0.username}", params.merge(email: 'gh@evercam.io').merge(credentials))
        expect(last_response.status).to eq(403)
        data = last_response.json
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

  describe 'GET /users/:id/credentials' do
    let(:password) { SecureRandom.base64(6)}
    let(:user) { create(:user, password: password) }
    let(:client) { create(:client) }
    let(:api_keys) { {api_id: client.exid, api_key: client.secret} }
    let(:parameters) { {password: password}.merge(api_keys) }

    context 'when properly authenticated' do
      context 'and a valid user name and password are provided' do
        it 'returns success and provides valid user credentials' do
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("api_id")).to eq(true)
          expect(data.include?("api_key")).to eq(true)
          expect(data["api_id"]).to eq(user.api_id)
          expect(data["api_key"]).to eq(user.api_key)
        end
      end

      context 'when a non-existent user name is specified' do
        it 'returns a not found error' do
          get("/users/blah/credentials", parameters)
          expect(last_response.status).to eq(404)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("User does not exist.")
        end
      end

      context 'when a password is not specified' do
        it 'returns a parameters error' do
          parameters.delete(:password)
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(400)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("password is missing")
        end
      end

      context 'when an invalid password is specified' do
        it 'returns an authentication error' do
          parameters[:password] = 'this is wrong'
          get("/users/#{user.username}/credentials", parameters)
          expect(last_response.status).to eq(401)
          data = last_response.json
          expect(data).not_to be_nil
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Invalid user name and/or password.")
        end
      end
    end

    context 'when no authentication details are provided' do
      it 'returns an unauthenticated error' do
        parameters.delete(:api_id)
        parameters.delete(:api_key)
        get("/users/#{user.username}/credentials", parameters)
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data).not_to be_nil
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when an non-existent API id is specified' do
      it 'returns an unauthenticated error' do
        parameters[:api_id] = 'blah'
        get("/users/#{user.username}/credentials", parameters)
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data).not_to be_nil
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when the API key does not match the API id specified' do
      it 'returns an unauthenticated error' do
        parameters[:api_key] = 'blah'
        get("/users/#{user.username}/credentials", parameters)
        expect(last_response.status).to eq(401)
        data = last_response.json
        expect(data).not_to be_nil
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end
  end

end

