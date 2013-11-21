require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/oauth2' do

  let(:app) { Evercam::WebApp }

  context 'when the user is not logged in' do
    it 'redirects them to the login page' do
      get('/oauth2/authorize', {}, {})
      rt = CGI.escape('/oauth2/authorize')

      expect(last_response.status).to eq(302)
      expect(last_response.location).
        to eq("http://example.org/login?rt=#{rt}")
    end
  end

end

