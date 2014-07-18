require 'data_helper'

module Evercam
  module Actors
    describe UserReset do

      subject { UserReset }

      let(:user0) { create(:user) }

      let(:inputs) do
        {
          username: user0.username,
          password: 'password123',
          confirmation: 'password123'
        }
      end

      describe 'invalid params' do

        it 'checks the username actually exists' do
          outcome = subject.run(inputs.merge(username: 'xxxx'))
          expect(outcome).to_not be_success
          expect(outcome.errors.symbolic[:username]).to eq(:exists)
        end

        it 'validates that the password and confirmation match' do
          outcome = subject.run(inputs.merge(password: 'xxxx'))
          expect(outcome).to_not be_success
          expect(outcome.errors.symbolic[:confirmation]).to eq(:match)
        end

      end

      describe 'user reset' do

        it 'updates the users password' do
          outcome = subject.run(inputs)
          expect(outcome).to be_success
          expect(user0.reload.password).to eq(inputs[:password])
        end

      end

    end
  end
end

