require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/docs' do

  let(:app) { Evercam::WebApp }

  context 'when the request is for root' do
    it 'renders it with an OK status' do
      get '/docs'
      expect(last_response.status).to eq(200)
    end
  end

  context 'when the doc exists in the api directory' do
    it 'renders it with an OK status' do
      get '/docs/api/v1/snapshots'
      expect(last_response.status).to eq(200)
    end
  end

  context 'when the doc does not exist' do
    it 'returns a NOT FOUND status' do
      get '/docs/api/v0/snapshots'
      expect(last_response.status).to eq(404)
    end
  end

end

