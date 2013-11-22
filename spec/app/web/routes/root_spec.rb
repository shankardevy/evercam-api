require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/root' do

  let(:app) { Evercam::WebApp }

  describe 'GET /about' do
    it 'renders with an OK status' do
      expect(get('/about').status).to eq(200)
    end
  end

  describe 'GET /privacy' do
    it 'renders with an OK status' do
      expect(get('/privacy').status).to eq(200)
    end
  end

  describe 'GET /jobs' do
    it 'renders with an OK status' do
      expect(get('/jobs').status).to eq(200)
    end
  end

end

