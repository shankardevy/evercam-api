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
          country: 'ie'
        }
      end

      subject { UserSignup }

      describe 'invalid params' do

        it 'checks the username is not already registered' do
          user0 = create(:user)
          params = valid.merge(username: user0.username)

          outcome = subject.run(params)
          expect(outcome).to_not be_success
        end

        it 'checks the email is not already registered' do
          user0 = create(:user)
          params = valid.merge(email: user0.email)

          outcome = subject.run(params)
          expect(outcome).to_not be_success
        end

        it 'checks the country code exists' do
          params = valid.merge(country: 'zz')
          outcome = subject.run(params)
          expect(outcome).to_not be_success
        end

      end

      describe 'account creation' do

        it 'sets the password to a 16 char random string' do
          User.expects(:create).with do |inputs|
            expect(inputs[:password].size).to eq(32)
          end.returns(build(:user))

          UserSignup.run(valid)
        end

        it 'sends an email confirmation message' do
          Mailers::UserMailer.expects(:confirm).with do |inputs|
            expect(inputs[:user]).to be_a(User)
            expect(inputs[:password]).to be_a(String)
          end

          UserSignup.run(valid)
        end

        it 'returns the created user' do
          user = UserSignup.run(valid).result
          expect(user).to eq(User.first)
        end

      end

    end

  end
end

