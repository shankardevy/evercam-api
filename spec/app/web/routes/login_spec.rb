require 'rack_helper'
require_app 'web/app'
require_lib 'actors'

describe 'WebApp routes/login' do

  let(:app) { Evercam::WebApp }

  let(:user) { create(:user, password: 'aaaa') }

  let(:env) { env_for({ session: { user: user.id } }) }

  describe 'GET /login' do

    context 'when the user is not logged in' do
      it 'renders with an OK status' do
        expect(get('/login').status).to eq(200)
      end
    end

    context 'when the user is already logged in' do

      context 'when no :rt param is provided' do
        it 'renders with an OK status' do
          get('/login', {}, env)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when an :rt param is provided' do
        it 'does a REDIRECT to the :rt param' do
          get('/login?rt=xxxx', {}, env)
          expect(last_response.status).to eq(302)
          expect(last_response.location).to eq('http://example.org/xxxx')
        end
      end

    end

  end

  describe 'POST /login' do

    context 'when the credentials are incorrect' do

      before(:each) do
        post('/login', { username: 'abcd', password: 'efgh' })
      end

      it 'shows an error message' do
        errors = last_response.alerts.css('.alert-error')
        expect(errors).to_not be_empty
      end

      it 'renders with an OK status' do
        expect(last_response.status).to eq(200)
      end

    end

    context 'when the credentials are correct' do

      let(:params) do
        { username: user.username, password: 'aaaa' }
      end

      it 'sets the :user key in session' do
        post('/login', params)
        expect(session[:user]).to eq(user.id)
      end

      context 'when no :rt param is provided' do
        it 'does a REDIRECT to the users home page' do
          post('/login', params)
          expect(last_response.status).to eq(302)
          expect(last_response.location).to eq("http://example.org/users/#{user.username}")
        end
      end

      context 'when an :rt param is provided' do
        it 'does a REDIRECT to the :rt param' do
          post('/login?rt=xxxx', params)
          expect(last_response.status).to eq(302)
          expect(last_response.location).to eq('http://example.org/xxxx')
        end
      end

    end

  end

  describe 'GET /logout' do

    before(:each) do
      get('/logout', {}, env)
    end

    it 'clears the :user key in session' do
      expect(session[:user]).to be_nil
    end

    it 'does a REDIRECT to the login page' do
      expect(last_response.status).to eq(302)
      expect(last_response.location).to eq('http://example.org/login')
    end

  end

end

