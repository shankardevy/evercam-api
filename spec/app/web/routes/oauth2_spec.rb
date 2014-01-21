require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/oauth2_router' do

  let(:app) { Evercam::WebApp }

  let(:camera0) { create(:camera) }

  let(:user0) { camera0.owner }

  let(:client0) { create(:client) }

  let(:env) { env_for(session: { user: user0.id }) }

  let(:valid) do
    {
      response_type: 'token',
      client_id: client0.exid,
      redirect_uri: client0.default_callback_uri,
      scope: "camera:view:#{camera0.exid}"
    }
  end

  describe 'GET /oauth2/authorize' do

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

          expect(last_response.status).to eq(400)
          expect(last_response.alerts).to_not be_empty
        end
      end

      context 'with an error not related to the redirect_uri' do
        it 'redirects the error to the redirect_uri' do
          params = valid.merge(response_type: 'xxxx')
          get('/oauth2/authorize', params, env)

          expect(last_response.status).to eq(302)
          expect(last_response.location).
            to start_with(client0.default_callback_uri)
        end
      end

    end

    context 'when the request is valid' do

      context 'with the user having previously approved all scopes' do

        let(:params) { valid }

        before(:each) do
          create(
            :access_token,
            grantor: user0,
            grantee: client0,
            scopes: [params[:scope]]
          )
          get('/oauth2/authorize', params, env)
        end

        it 'creates a new access token for the client' do
          expect(client0.reload.tokens.count).to eq(2)
        end

        it 'redirects back to the redirect_uri' do
          expect(last_response.status).to eq(302)
          expect(last_response.location).
            to start_with(params[:redirect_uri])
        end

        it 'includes the new access token in the fragment' do
          expect(last_response.location).
            to have_fragment({ access_token: client0.reload.tokens.last.request })
        end

      end

      context 'with the user needing to approve one or more scopes' do

        let(:camera1) { create(:camera, owner: user0) }

        let(:params) { valid.merge(scope: "camera:view:#{camera1.exid}") }

        before(:each) { get('/oauth2/authorize', params, env) }

        it 'displays the approval request to the user' do
          expect(last_response.status).to eq(200)
        end

      end

    end

  end

  describe 'POST /oauth2/authorize' do

    let(:camera1) { create(:camera, owner: user0) }

    let(:params) { valid.merge(scope: "camera:view:#{camera1.exid}") }

    context 'when the user approves the authorization' do
      it 'issues an access token and redirect the user agent' do
        post('/oauth2/authorize', params.merge(action: 'approve'), env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to have_fragment({ access_token: client0.reload.tokens.last.request })
      end
    end

    context 'when the user declines the authorization' do
      it 'redirects the user agent with an :access_denied error' do
        post('/oauth2/authorize', params.merge(action: 'decline'), env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to have_fragment({ error: :access_denied })
      end
    end

  end

end

