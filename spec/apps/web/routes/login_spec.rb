require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/login' do

  let(:app) { Evercam::WebApp }

  let(:user) { create(:user, password: 'aaaa') }

  describe 'GET /login' do

    context 'when the user is not logged in' do
      it { renders_with_ok get('/login') }
    end

    context 'when the user is already logged in' do

      let(:env) do
        env_for({ session: { user: user.id } })
      end

      context 'when no :rt param is provided' do
        it { renders_with_ok get('/login', {}, env) }
      end

      context 'when an :rt param is provided' do
        it { temp_redirects_to 'xxxx', get('/login?rt=xxxx', {}, env) }
      end

    end

  end

  describe 'POST /login' do

    context 'when the credentials are incorrect' do

      subject { post('/login', { username: '', password: '' }) }

      it { shows_an_error }
      it { renders_with_ok }

    end

    context 'when the credentials are correct' do

      let(:params) do
        { username: user.username, password: 'aaaa' }
      end

      it { sets_session_key :user, user.id, post('/login', params) }

      context 'when no :rt param is provided' do
        it { temp_redirects_to "/users/#{user.username}", post('/login', params) }
      end

      context 'when an :rt param is provided' do
        it { temp_redirects_to 'xxxx', post('/login?rt=xxxx', params) }
      end

    end

  end

  describe 'GET /logout' do

    let(:env) do
      env_for({ session: { user: user.id } })
    end

    subject { get('/logout', {}, env) }

    it { clears_session_key :user }
    it { temp_redirects_to '/login' }

  end

end

