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

    let(:params) do
      {
        forename: 'Garrett',
        lastname: 'Heaver',
        username: 'garrettheaver',
        email: 'garrett@evercam.io',
        country: 'ie'
      }
    end

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

end

