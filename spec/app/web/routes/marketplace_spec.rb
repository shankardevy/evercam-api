require 'rack_helper'
require_app 'web/app'

describe 'WebApp routes/marketplace' do

  let(:app) { Evercam::WebApp }

  context 'GET /marketplace' do
    it 'renders with an OK status' do
      expect(get('/marketplace').status).to eq(200)
    end
  end

  context 'POST /marketplace/idea' do

    it 'redirects the marketplace index' do
      post('/marketplace/idea', { email: 'xxxx', idea: '' })
      expect(last_response.status).to eq(302)
      expect(last_response.location).to end_with('/marketplace')
    end

    context 'when the parameters are valid' do

      before(:each) do
        post('/marketplace/idea', { email: 'garrett@evercam.io', idea: 'timelapse' })
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
        post('/marketplace/idea', { email: 'xxxx', idea: '' })
        follow_redirect!

        errors = last_response.alerts.css('.alert-error')
        expect(errors).to_not be_empty
      end
    end

  end

end

