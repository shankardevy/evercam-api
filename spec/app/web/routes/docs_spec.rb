require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/docs' do

  let(:app) { Evercam::WebApp }

  context 'when the request is for root' do
    it 'renders it with an OK status' do
      expect(get('/docs').status).to eq(200)
    end
  end

  context 'when the doc is listed on the site' do
    it 'renders its template with an OK status' do
      get('/docs').html.css('.left-nav ul')[0].css('a').each do |a|
        expect(get(a[:href]).status).to eq(200)
      end
    end
  end

  context 'when the doc does not exist' do
    it 'returns a NOT FOUND status' do
      expect(get('/docs/xxxx').status).to eq(404)
    end
  end

end

