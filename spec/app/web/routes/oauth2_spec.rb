require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/oauth2' do

  let(:app) { Evercam::WebApp }

  let(:atsr) { create(:access_token_stream_right) }

  let(:user0) { atsr.stream.owner }

  let(:client0) { atsr.token.grantee }

  let(:stream0) { atsr.stream }

  let(:env) { env_for(session: { user: user0.id }) }

  let(:valid) do
    {
      response_type: 'token',
      client_id: client0.exid,
      redirect_uri: client0.default_callback_uri,
      scope: "stream:#{atsr.name}:#{stream0.name}"
    }
  end

  context 'when the user is not logged in' do
    it 'redirects the visitor to the login page' do
      get('/oauth2/authorize', {}, {})
      rt = CGI.escape('/oauth2/authorize')

      expect(last_response.status).to eq(302)
      expect(last_response.location).
        to end_with("/login?rt=#{rt}")
    end
  end

  context 'when the request is invalid' do

    context 'with an unknown client or an illegal redirect_uri' do
      it 'redirects the error to the local error page' do
        params = valid.merge(client_id: 'xxxx')
        get('/oauth2/authorize', params, env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to end_with('/errors/400')
      end
    end

    context 'with an error not related to the redirect_uri' do
      it 'redirects the error to the redirect_uri' do
        params = valid.merge(response_type: 'xxxx')
        get('/oauth2/authorize', params, env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to start_with(atsr.token.grantee.default_callback_uri)
      end
    end

  end

  context 'when the request is valid' do


    context 'with the user having previously approved all scopes' do

      let(:params) { valid  }

      before(:each) { get('/oauth2/authorize', params, env) }

      it 'creates a new access token for the client' do
        client = atsr.token.grantee.reload
        expect(client.tokens.count).to eq(2)
      end

      it 'redirects back to the redirect_uri' do
        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to start_with(params[:redirect_uri])
      end

      it 'includes the new access token in the fragment' do
        atsr1 = AccessTokenStreamRight.order(:created_at).last
        expect(last_response.location).
          to have_fragment({ access_token: atsr1.token.request })
      end

    end

    context 'with the user needing to approve one or more scopes' do

      let(:stream1) { create(:stream, owner: user0) }

      let(:params) { valid.merge(scope: "stream:view:#{stream1.name}") }

      before(:each) { get('/oauth2/authorize', params, env) }

      it 'displays the approval request to the user' do
        expect(last_response.status).to eq(200)
      end

    end

  end

end

