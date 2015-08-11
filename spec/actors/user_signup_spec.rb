require 'data_helper'

module Evercam
  module Actors

    describe UserSignup do

      let(:valid) do
        {
          firstname: 'Garrett',
          lastname: 'Heaver',
          username: "user#{Time.now.to_i}",
          email: 'garrett@evercam.io',
          password: 'password',
          country: create(:country).iso3166_a2
        }
      end

      subject { UserSignup }

      describe 'invalid params' do

        it 'raises an exception if the user name is already registered' do
          user0 = create(:user)
          params = valid.merge(username: user0.username)

          expect {subject.run(params)}.to raise_error(Evercam::ConflictError,
                                                      "The username '#{user0.username}' is already registered.")
        end

        it 'raises an exception if the email address is already registered' do
          user0 = create(:user)
          params = valid.merge(email: user0.email)

          expect {subject.run(params)}.to raise_error(Evercam::ConflictError,
                                                      "The email address '#{user0.email}' is already registered.")
        end

        it 'raises an exception if an invalid country code is specified' do
          params = valid.merge(country: "blah")
          expect {subject.run(params)}.to raise_error(Evercam::NotFoundError,
                                                      "The country code 'blah' is not valid.")
        end

        it 'checks that the email address follows a basic format' do
          params = {}.merge(valid).merge(email: "email#{Time.now.to_i}.blah.com")
          outcome = subject.run(params)
          expect(outcome).to_not be_success

          errors = outcome.errors.symbolic
          expect(errors[:email]).to eq(:invalid)
        end

      end

      describe 'account creation' do

        it 'creates a user with provided String password' do
          user   = create(:user)
          double = User.expects(:new).at_least_once

          double.returns(user)

          user = UserSignup.run(valid)
        end

        it 'sends an email confirmation message to the user' do
          double = Mailers::UserMailer.expects(:confirm).with do |inputs|
            expect(inputs[:user]).to be_a(User)
            expect(inputs[:code]).to be_a(String)
          end

          double.returns(nil)
          UserSignup.run(valid)
        end

        it 'returns the created user' do
          user = UserSignup.run(valid).result
          found_user = User.where(email: 'garrett@evercam.io')
          expect(user.id).to eq(found_user.first.id)
        end

      end

    end

  end
end

