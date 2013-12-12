require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/root' do

  let(:app) { Evercam::WebApp }

  ['/', '/about', '/privacy', '/terms', '/jobs',
   '/marketplace', '/media'].each do |url|
    describe "GET #{url}" do
      it 'renders with an OK status' do
        expect(get(url).status).to eq(200)
      end
    end
  end

  describe 'POST /interested' do
    context 'when the email is valid' do

      it 'thanks the user for their interest' do
        post('/interested', { email: 'garrett@evercam.io' })
        follow_redirect!

        expect(last_response.body).
          to match(/thank you for your interest/i)
      end

      it 'creates a cookie for the email and creation date' do
        post('/interested', { email: 'garrett@evercam.io' })
        follow_redirect!

        cookies = rack_mock_session.cookie_jar
        expect(cookies['email']).to eq('garrett@evercam.io')
        expect(cookies['created_at']).to_not be_nil
      end

    end

    context 'when the email is invalid' do
      it 'tells the user the address is invalid' do
        post('/interested', { email: 'xxxx' })
        follow_redirect!

        expect(last_response.body).
          to match(/does not appear to be valid/i)
      end
    end
  end

end

