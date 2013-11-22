require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/jobs' do

  let(:app) { Evercam::WebApp }

  describe 'GET /jobs' do
    it 'renders with an OK status' do
      expect(get('/jobs').status).to eq(200)
    end
  end

end

