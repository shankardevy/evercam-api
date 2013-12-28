require 'rack_helper'
require_app 'web/app'
require_lib 'actors'

describe 'WebApp routes/signup' do

  let(:app) { Evercam::WebApp }

  describe 'GET /signup' do
    it 'renders with an OK status' do
      get '/signup'
      expect(last_response.status).to eq(200)
    end
  end

  describe 'POST /signup' do

    let(:params) do
      build(:user).values.merge(country: create(:country).iso3166_a2)
    end

    context 'when it creates the user' do
      it 'redirects to /login and displays a success message' do
        post('/signup', params)

        expect(last_response.location).to end_with('/login')
        follow_redirect!

        expect(last_response.body).to match(/congratulations/i)
      end
    end

    context 'when the params are invalid' do
      it 'stays on /signup and displays the errors' do
        post('/signup', params.merge(country: 'xx'))

        expect(last_response.location).to end_with('/signup')
        follow_redirect!

        expect(last_response.body).to match(/errors/i)
      end
    end

  end

  describe '/confirm' do

    context 'when the credentials are invalid' do
      it 'redirects the user to the signup page' do
        user0 = create(:user, password: 'aaaa')
        get("/confirm?u=#{user0.username}&c=xxxx")

        expect(last_response.status).to eq(302)
        expect(last_response.location).to end_with('/signup')
      end
    end

    context 'when the user is already confirmed' do
      it 'redirects the user to the login page' do
        user0 = create(:user, confirmed_at: Time.now)
        get("/confirm?u=#{user0.username}&c=xxxx")

        expect(last_response.status).to eq(302)
        expect(last_response.location).to end_with('/login')
      end
    end

    describe 'GET' do

      context 'when the params are valid' do
        it 'renders with the users name' do
          user0 = create(:user, password: 'xxxx')
          get("/confirm?u=#{user0.username}&c=xxxx")

          expect(last_response.status).to eq(200)
          expect(last_response.body).to match(user0.forename)
        end
      end

    end

    describe 'POST' do

      let(:user0) { create(:user, password: 'xxxx') }

      context 'when the passwords do not match' do
        it 'show the user an error message' do
          params = { password: 'abcd', confirmation: 'efgh' }
          post("/confirm?u=#{user0.username}&c=xxxx", params)
          expect(last_response.alerts(:error)).to_not be_empty
        end
      end

      context 'when the password do match' do

        before(:each) do
          params = { password: 'abcd', confirmation: 'abcd' }
          post("/confirm?u=#{user0.username}&c=xxxx", params)
        end

        it 'sets up a session for the user' do
          expect(session[:user]).to eq(user0.pk)
        end

        it 'redirects to the users index page' do
          expect(last_response.status).to eq(302)
          expect(last_response.location).to end_with("/users/#{user0.username}")
        end

        it 'updates the users password' do
          expect(user0.reload.password).to eq('abcd')
        end

      end

    end

  end

  describe 'POST /interested' do

    it 'posts to here from the homepage signup form' do
      form = get('/').html.css('form').first
      expect(form[:action]).to eq('/interested')
    end

    context 'when the email is valid' do

      it 'thanks the user for their interest' do
        post('/interested', { email: 'garrett@evercam.io' })
        follow_redirect!

        expect(last_response.body).
          to match(/thank you for your interest/i)
      end

      it 'creates a cookie for the email and creation date' do
        post('/interested', { email: 'garrett@evercam.io' })
        follow_redirect!

        cookies = rack_mock_session.cookie_jar
        expect(cookies['email']).to eq('garrett@evercam.io')
        expect(cookies['created_at']).to_not be_nil
      end

    end

    context 'when the email is invalid' do
      it 'tells the user the address is invalid' do
        post('/interested', { email: 'xxxx' })
        follow_redirect!

        expect(last_response.body).
          to match(/does not appear to be valid/i)
      end
    end

  end

end

