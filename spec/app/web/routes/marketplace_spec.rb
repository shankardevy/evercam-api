require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/marketplace' do

  let(:app) { Evercam::WebApp }

  context 'GET /marketplace' do
    it 'renders with an OK status' do
      expect(get('/marketplace').status).to eq(200)
    end
  end

end

