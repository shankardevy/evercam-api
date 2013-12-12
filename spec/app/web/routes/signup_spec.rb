require 'rack_helper'
require_app 'web/app'
require_lib 'actors'

describe 'WebApp routes/signup' do

  let(:app) { Evercam::WebApp }

  describe 'GET /signup' do
    it 'renders with an OK status' do
      get '/signup'
      expect(last_response.status).to eq(200)
    end
  end

  describe 'POST /signup' do

    let(:params) { build(:user).values.merge(country: 'ie') }

    context 'when it creates the user' do
      it 'redirects to /login and displays a success message' do
        post('/signup', params)

        expect(last_response.location).to end_with('/login')
        follow_redirect!

        expect(last_response.body).to match(/congratulations/i)
      end
    end

    context 'when the params are invalid' do
      it 'stays on /signup and displays the errors' do
        post('/signup', params.merge(country: 'xx'))

        expect(last_response.location).to end_with('/signup')
        follow_redirect!

        expect(last_response.body).to match(/errors/i)
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

