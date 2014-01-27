require 'rack_helper'
require_app 'api/v1'

module Evercam
  describe WithAuth do

    subject { WithAuth.new(env) }

    let!(:user) { create(:user, username: 'x', password: 'y') }

    context 'when no authentication is provided' do

      let(:env) { { 'rack.session' => {} } }

      describe '#token' do
        it 'returns nil' do
          expect(subject.token).to be_nil
        end
      end

    end

    context 'when basic authentication is provided' do

      context 'when the credentials are not valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic xxxx' } }

        describe '#token' do
          it 'raises an AuthenticationError' do
            expect{ subject.token }.to raise_error(AuthenticationError)
          end
        end

      end

      context 'when the credentials are valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic eDp5' } }

        describe '#token' do
          it 'returns the users permanent token' do
            expect(subject.token).to eq(user.token)
          end
        end

      end

    end

    context 'when a user session cookie is available' do

      context 'when the cookie is not valid' do

        let(:env) { env_for(session: { user: '0' }) }

        describe '#token' do
          it 'raises an AuthenticationError' do
            expect{ subject.token }.to raise_error(AuthenticationError)
          end
        end

      end

      context 'when the cookie is valid' do

        let(:env) { env_for(session: { user: user.id }) }

        describe '#token' do
          it 'returns the users permanent token' do
            expect(subject.token).to eq(user.token)
          end
        end

      end

    end

    context 'when an oauth access token is provided' do

      let(:token) { create(:access_token) }

      let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token.request}" } }

      context 'when the token does not exist' do

        before(:each) { token.delete }

        describe '#token' do
          it 'raises an AuthenticationError' do
            expect{ subject.token }.to raise_error(AuthenticationError)
          end
        end

      end

      context 'when the token is invalid' do

        before(:each) { token.update(is_revoked: true) }

        describe '#token' do
          it 'raises an AuthenticationError' do
            expect{ subject.token }.to raise_error(AuthenticationError)
          end
        end

      end

      context 'when the token is valid' do
        describe '#token' do
          it 'it returns the temporary access token' do
            expect(subject.token).to eq(token)
          end
        end
      end

    end

  end

end

