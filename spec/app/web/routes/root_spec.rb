require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/root' do

  let(:app) { Evercam::WebApp }

  ['/', '/about', '/privacy', '/terms', '/jobs'].each do |url|
    describe "GET #{url}" do
      it 'renders with an OK status' do
        expect(get(url).status).to eq(200)
      end
    end
  end

end

