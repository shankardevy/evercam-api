require 'rack_helper'
require_app 'web/app'

describe 'GET /login' do

  let(:app) { Evercam::WebApp }

  context 'when the user is not logged in' do
    it { renders_with_ok get('/login') }
  end

  context 'when the user is already logged in' do

    let(:env) do
      env_for({ session: { user: create(:user).id } })
    end

    context 'when no :rt param is provided' do
      it { renders_with_ok get('/login', {}, env) }
    end

    context 'when an :rt param is provided' do
      it { temp_redirects_to 'xxxx', get('/login?rt=xxxx', {}, env) }
    end

  end

end

