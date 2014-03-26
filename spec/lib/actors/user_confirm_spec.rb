require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe UserConfirm do

      subject { UserConfirm }

      let(:user0) do
        create(:user, password: 'abcd')
      end

      describe 'invalid params' do

        it 'checks the username actually exists' do
          outcome = subject.run(username: 'xxxx', confirmation: 'abcd')
          expect(outcome).to_not be_success
          expect(outcome.errors.symbolic[:username]).to eq(:exists)
        end

        # TODO: reimplement confirmation code
        #it 'validates that the confirmation code is correct' do
        #  outcome = subject.run(username: user0.username, confirmation: 'xxxx')
        #  expect(outcome).to_not be_success
        #  expect(outcome.errors.symbolic[:confirmation]).to eq(:invalid)
        #end

        it 'validates that the account is not already validated' do
          user0.update(confirmed_at: Time.now)
          outcome = subject.run(username: user0.username, confirmation: 'abcd')

          expect(outcome).to_not be_success
          expect(outcome.errors.symbolic[:username]).to eq(:confirmed)
        end

      end

      describe 'user confirmation' do
        it 'sets #confirmed_at' do
          outcome = subject.run(username: user0.username, confirmation: 'abcd')
          expect(outcome).to be_success
          expect(user0.reload.confirmed_at).to_not be_nil
        end
      end

    end
  end
end

