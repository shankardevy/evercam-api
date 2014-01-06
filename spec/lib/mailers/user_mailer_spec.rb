require 'data_helper'
require_lib 'mailers'

module Evercam
  module Mailers
    describe UserMailer do

      let(:user) { create(:user) }
      let(:password) { SecureRandom.hex(16) }

      subject { UserMailer }

      describe '#confirm' do

        let(:result) do
          subject.new(user: user, password: password).confirm
        end

        it 'renders the content correctly' do
          expect(result[:to]).to eq(user.email)
          expect(result[:subject]).to match(/confirm/i)
        end

        it 'includes the username and password' do
          expect(result[:body]).to match(user.username)
          expect(result[:body]).to match(password)
        end

      end

      describe '#interested' do

        let(:result) do
          request = stub(user_agent: 'aaaa', ip: 'bbbb')
          subject.new(email: 'xxxx', request: request).interested
        end

        it 'renders the content correctly' do
          expect(result[:body]).to_not be_nil
        end

      end

      describe '#app_idea' do

        let(:result) do
          request = stub(user_agent: 'aaaa', ip: 'bbbb')
          subject.new(email: 'xxxx', idea: 'yyyy', request: request).app_idea
        end

        it 'renders the content correctly' do
          expect(result[:body]).to_not be_nil
        end

      end

    end
  end
end

