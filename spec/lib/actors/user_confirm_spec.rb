require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe UserConfirm do

      subject { UserConfirm }

      describe 'invalid params' do
        it 'checks the username actually exists' do
          outcome = subject.run(username: 'xxxx')
          expect(outcome).to_not be_success
          expect(outcome.errors.symbolic[:username]).to eq(:exists)
        end
      end

      describe 'user confirmation' do
        it 'sets #confirmed_at' do
          user0 = create(:user)
          outcome = subject.run(username: user0.username)

          expect(outcome).to be_success
          expect(user0.reload.confirmed_at).to_not be_nil
        end
      end

    end
  end
end

