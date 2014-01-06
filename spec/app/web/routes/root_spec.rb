require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/root' do

  let(:app) { Evercam::WebApp }

  ['/', '/about', '/privacy', '/terms', '/jobs', '/media', '/contact'].each do |url|
    describe "GET #{url}" do
      it 'renders with an OK status' do
        expect(get(url).status).to eq(200)
      end
    end
  end

  it 'includes google analytics' do
    script = get('/').html.css('#GoogleAnalyticsScriptTag')
    expect(script).to_not be_empty
  end

  context 'POST /contact' do

    it 'redirects to GET /contact' do
      post('/contact')
      expect(last_response.status).to eq(302)
      expect(last_response.location).to end_with('/contact')
    end

    context 'when the parameters are valid' do

      before(:each) do
        Intercom::MessageThread.expects(:create)
        post('/contact', { name: 'Garrett', email: 'garrett@evercam.io', body: 'timelapse' })
        follow_redirect!
      end

      it 'displays a thank you message' do
        info = last_response.alerts.css('.alert-success')
        expect(info).to_not be_empty
      end

      it 'creates a cookie for the email and creation date' do
        cookies = rack_mock_session.cookie_jar
        expect(cookies['email']).to eq('garrett@evercam.io')
        expect(cookies['created_at']).to_not be_nil
      end

    end

    context 'when the parameters are invalid' do
      it 'displays an error message' do
        post('/contact', { name: '', email: 'xxxx', body: '' })
        follow_redirect!

        errors = last_response.alerts.css('.alert-error')
        expect(errors).to_not be_empty
      end

    end

  end

end

