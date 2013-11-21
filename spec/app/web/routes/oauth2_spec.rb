require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/oauth2' do

  let(:app) { Evercam::WebApp }

  let(:user) { create(:user) }

  let(:client) { create(:client) }

  let(:env) { env_for(session: { user: user.id }) }

  let(:params) do
    {
      response_type: 'token',
      client_id: client.exid,
      redirect_uri: client.default_callback_uri,
      scope: 'stream:view:xxxx'
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
        get('/oauth2/authorize', params.merge(client_id: 'xxxx'), env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to end_with('/oauth2/error')
      end
    end

    context 'with an which does not include the redirect_uri' do
      it 'redirects the error to the redirect_uri' do
        get('/oauth2/authorize', params.merge(response_type: 'xxxx'), env)

        expect(last_response.status).to eq(302)
        expect(last_response.location).
          to start_with(client.default_callback_uri)
      end
    end

  end

  context 'when the request is valid' do

    context 'with the user having previously approved all scopes' do
      it 'redirects to the redirect_uri with an access token'
    end

    context 'with the user needing to approve one or more scopes' do
      it 'displays the approval request to the user'
    end

  end

end

