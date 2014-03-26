require 'data_helper'
require_lib 'mailers'
require_lib 'actors'

module Evercam
  module Actors
    describe UserSignup do

      let(:valid) do
        {
          forename: 'Garrett',
          lastname: 'Heaver',
          username: 'garrettheaver',
          email: 'garrett@evercam.io',
          password: 'password',
          country: create(:country).iso3166_a2
        }
      end

      subject { UserSignup }

      describe 'invalid params' do

        it 'checks the username is not already registered' do
          user0 = create(:user)
          params = valid.merge(username: user0.username)

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:username]).to eq(:exists)
        end

        it 'checks the email is not already registered' do
          user0 = create(:user)
          params = valid.merge(email: user0.email)

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:email]).to eq(:exists)
        end

        it 'checks the country code exists' do
          params = valid.merge(country: 'zz')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:country]).to eq(:invalid)
        end

      end

      describe 'account creation' do

        it 'creates a user with provided String password' do
          VCR.use_cassette('API_users/account_creation') do
            double = User.expects(:create).with do |inputs|
              expect(inputs[:password]).to be_a(String)
            end

            double.returns(create(:user))
            UserSignup.run(valid)
          end
        end

        it 'sends an email confirmation message to the user' do
          VCR.use_cassette('API_users/account_creation') do
            double = Mailers::UserMailer.expects(:confirm).with do |inputs|
              expect(inputs[:user]).to be_a(User)
              expect(inputs[:password]).to be_a(String)
            end

            double.returns(nil)
            UserSignup.run(valid)
          end
        end

        it 'returns the created user' do
          VCR.use_cassette('API_users/account_creation') do
            user = UserSignup.run(valid).result
            expect(user.id).to eq(User.first.id)
          end
        end

      end

    end

  end
end

