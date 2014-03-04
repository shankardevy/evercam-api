require 'rack_helper'
require 'cgi'
require 'uri'
require '3scale_client'
require 'webmock/rspec'
require_app 'web/app'

describe 'WebApp routes/oauth2_router' do

  let(:app) { Evercam::WebApp }

  let(:camera0) { create(:camera, is_public: false) }

  let(:user0) { camera0.owner }

  let(:client0) { create(:client, exid: 'client0', callback_uris: nil) }

  let(:env) { env_for(session: { user: user0.id }) }

  let(:valid) do
    {
      response_type: 'token',
      client_id: client0.exid,
      redirect_uri: client0.default_callback_uri,
      scope: "camera:view:#{camera0.exid}"
    }
  end

  let(:get_parameters) do
    {client_id: 'client0',
     redirect_uri: 'https://www.google.com',
     response_type: 'code',
     scope: 'cameras:view'}
  end

  let(:post_parameters) do
    {client_id: 'client0',
     client_secret: 'abcdefgh',
     redirect_uri: 'https://www.google.com',
     grant_type: 'authorization_code'}
  end

  describe 'GET /oauth2/authorize' do

    context 'when client id is not specified' do
      it 'generates a bad request response' do
        get_parameters.delete(:client_id)
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(400)
      end
    end

    context 'when a redirect URI is not specified' do
      it 'generates a bad request response' do
        get_parameters.delete(:redirect_uri)
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(400)
      end
    end

    context 'when a response type is not specified' do
      it 'generates a bad request response' do
        get_parameters.delete(:response_type)
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(400)
      end
    end

    context 'when an invalid response type is specified' do
      it 'generates a bad request response' do
        get_parameters[:response_type] = 'xxxx'
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(400)
      end
    end

    context 'when a scope is not specified' do
      it 'generates a bad request response' do
        get_parameters.delete(:scope)
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(400)
      end
    end

    context 'when the user is not logged in' do
      it 'redirects the visitor to the login page' do
        get('/oauth2/authorize', get_parameters, {})
        rt = CGI.escape('/oauth2/authorize')

        expect(last_response.status).to eq(302)
        uri = URI.parse(last_response.location)
        expect(uri.path).to eq("/login")
      end
    end

    context "when the user is logged in" do
      context "and the requester does not have the required permissions" do
        it "shows the grant permissions page" do
            get('/oauth2/authorize', get_parameters, env)
            rt = CGI.escape('/oauth2/authorize')

            expect(last_response.status).to eq(200)
        end
      end

      context "and the requester has all the need permissions" do
        before(:each) do
          token = create(:access_token, client: client0)
          AccessRightSet.new(camera0, client0).grant(AccessRight::VIEW)
          token.save
        end

        context 'and the request is valid' do
          it "redirects to the callers redirect URI passing in the authorization code" do
            get('/oauth2/authorize', get_parameters, env)
            rt = CGI.escape('/oauth2/authorize')

            expect(last_response.status).to eq(302)
            uri = URI.parse(last_response.location)
            parameters = CGI::parse(uri.query)
            expect(uri.host).to eq("www.google.com")
            expect(uri.scheme).to eq("https")
            expect(parameters.empty?).to eq(false)
            expect(parameters.include?("code")).to eq(true)
          end
        end
      end
    end

  end

  describe 'POST /oauth/authorize' do
    context "when the rights grant is declined" do
      it "redirects to the callback URI with an error" do
        parameters = {action: 'decline', redirect_uri: 'https://www.google.com',
                      client_id: client0.exid, scope: 'cameras:view'}
        post("/oauth2/authorize", parameters, env)
        expect(last_response.status).to eq(302)
        uri = URI.parse(last_response.location)
        values = CGI.parse(uri.query)
        expect(uri.host).to eq("www.google.com")
        expect(values.include?("error")).to eq(true)
        expect(values["error"]).to eq(["access_denied"])
      end
    end

    context "when the rights grant is approved" do
      it "redirects to the callback URI with a code" do
        parameters = {action: 'approve', redirect_uri: 'https://www.google.com',
                      client_id: client0.exid, scope: 'cameras:view'}
        post("/oauth2/authorize", parameters, env)
        expect(last_response.status).to eq(302)
        uri = URI.parse(last_response.location)
        values = CGI.parse(uri.query)
        expect(uri.host).to eq("www.google.com")
        expect(values.include?("code")).to eq(true)
      end
    end
  end

  describe 'POST /oauth2/token' do
    before(:each) { client0.save }

    context "when g not given a code parameter" do
      it "generates a bad request response" do
        post_parameters.delete(:code)
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when not given a client id parameter" do
      it "generates a bad request response" do
        post_parameters.delete(:client_id)
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when not given a client secret parameter" do
      it "generates a bad request response" do
        post_parameters.delete(:client_secret)
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when not given a redirect URI parameter" do
      it "generates a bad request response" do
        post_parameters.delete(:redirect_uri)
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when not given a grant type parameter" do
      it "generates a bad request response" do
        post_parameters.delete(:grant_type)
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when given an invalid grant type parameter" do
      it "generates a bad request response" do
        post_parameters[:grant_type] = "bbbb"
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when given non-existent client id parameter" do
      it "generates a bad request response" do
        post_parameters[:client_id] = "ningy"
        post("/oauth2/token", post_parameters, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "for requests that hit 3Scale" do
      before(:each) do
        stub_request(:get, "http://su1.3scale.net/transactions/authrep.xml?%5Busage%5D%5Bhits%5D=1&app_id=client0&app_key=abcdefgh&provider_key=b25bc9166b8805fc26a96f1130578d2b").
           with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Host'=>'su1.3scale.net', 'User-Agent'=>'Ruby'}).
           to_return(:status => 200,
                     :body => "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<status>\n  <authorized>true</authorized>\n  <plan>Pay As You Go ($20 for 10,000 hits)</plan>\n</status>",
                     :headers => {})
      end

      context "when given a code for a revoked access token" do
        let(:revoked_token) { create(:access_token, is_revoked: true, refresh: 'abcdef', client: client0).save }

        it "generates a bad request response" do
          post_parameters[:code] = revoked_token.refresh_code
          post("/oauth2/token", post_parameters, env)
          expect(last_response.status).to eq(400)
        end
      end

      context "called for a proper access token" do
        let(:proper_token) { create(:access_token, is_revoked: false, refresh: 'abcdef', client: client0).save }

        it "redirects to the redirect URI with appropriate parameters" do
          post_parameters[:code] = proper_token.refresh_code
          post("/oauth2/token", post_parameters, env)
          expect(last_response.status).to eq(302)
        end
      end
    end

  end


  describe 'GET /oauth2/tokeninfo' do
    before(:each) { client0.save }

    context "when not given a code parameter" do
      it "generates a bad request response" do
        get("/oauth2/tokeninfo", {}, env)
        expect(last_response.status).to eq(400)
      end
    end

    context "when invoked without a user being logged in" do
      it "generates an error response" do
        get("/oauth2/tokeninfo", {code: '12345'}, {user: nil})
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data.include?("error")).to eq(true)
        expect(data["error"]).to eq("invalid_token")
      end
    end

    context "when invoked with an invalid code" do
      it "generates an error response" do
        get("/oauth2/tokeninfo", {code: 'xxxxx'}, env)
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data.include?("error")).to eq(true)
        expect(data["error"]).to eq("invalid_token")
      end
    end

    context "when invoked with for an invalid access token" do
      let(:access_token) { create(:access_token, is_revoked: true, refresh: 'token01').save }

      it "generates an error response" do
        get("/oauth2/tokeninfo", {code: access_token.refresh_code}, env)
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)
        expect(data.include?("error")).to eq(true)
        expect(data["error"]).to eq("invalid_token")
      end
    end

    context "when invoked for a valid access token with a logged in user" do
      let(:access_token) { create(:access_token, refresh: 'token02', client: client0).save }

      it "generates a success response" do
        get("/oauth2/tokeninfo", {code: access_token.refresh_code}, env)
        expect(last_response.status).to eq(200)
        data = JSON.parse(last_response.body)

        expect(data.include?("audience")).to eq(true)
        expect(data.include?("access_token")).to eq(true)
        expect(data.include?("expires_in")).to eq(true)
        expect(data.include?("userid")).to eq(true)

        expect(data["audience"]).to eq(client0.exid)
        expect(data["access_token"]).to eq(access_token.request)
        expect(data["userid"]).to eq(user0.username)
      end
    end

    context "when invoked with a redirect_uri parameter" do
      let(:access_token) { create(:access_token, refresh: 'token02', client: client0).save }

      it "generates a redirect response" do
        get("/oauth2/tokeninfo", {code: access_token.refresh_code, redirect_uri: "https://www.blah.com"}, env)
        expect(last_response.status).to eq(302)
        uri        = URI.parse(last_response.location)
        parameters = CGI::parse(uri.query)

        expect(uri.host).to eq("www.blah.com")

        expect(parameters.include?("audience")).to eq(true)
        expect(parameters.include?("access_token")).to eq(true)
        expect(parameters.include?("expires_in")).to eq(true)
        expect(parameters.include?("userid")).to eq(true)

        expect(parameters["audience"]).to eq([client0.exid])
        expect(parameters["access_token"]).to eq([access_token.request])
        expect(parameters["userid"]).to eq([user0.username])
      end
    end
  end

  describe "GET /oauth2/revoke" do
    context "when invoked without a token parameter" do
      it "generates an error response" do
        get("/oauth2/revoke", {})
        expect(last_response.status).to eq(400)
      end
    end

    context "when invoked for a non-existent token" do
      it "generates a not found error" do
        get("/oauth2/revoke", {token: 'xxxxx'})
        expect(last_response.status).to eq(404)
      end
    end

    context "when invoked with a valid access token" do
      let(:access_token) { create(:access_token, client: client0).save }

      it "returns success" do
        get("/oauth2/revoke", {token: access_token.request})
        expect(last_response.status).to eq(200)
      end
    end

    context "when invoked with a valid refresh token" do
      let(:access_token) { create(:access_token, refresh: 'token03', client: client0).save }

      it "returns success" do
        get("/oauth2/revoke", {token: access_token.refresh_code})
        expect(last_response.status).to eq(200)
      end
    end
  end

end

