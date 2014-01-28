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

    describe '#demand' do

      context 'when no auth is provided' do

        let(:env) { { 'rack.session' => {} } }

        it 'raises an AuthenticationError' do
          expect{ subject.demand }.to raise_error(AuthenticationError)
        end

      end

      context 'when the auth is not valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic xxxx' } }

        it 'raises an AuthenticationError' do
          expect{ subject.demand }.to raise_error(AuthenticationError)
        end

      end

      context 'when the auth is valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic eDp5' } }

        it 'yields the token and the grantor into the block' do
          expect{ |b| subject.demand(&b) }.
            to yield_with_args(user.token, user)
        end

        it 'returns the value output of the block' do
          output = subject.demand { |t,u| 12345 }
          expect(output).to eq(12345)
        end

      end

    end


    describe '#allow?' do

      context 'when no auth is provided' do

        let(:env) { { 'rack.session' => {} } }

        it 'passes nil into the block for token and grantor' do
          expect{ |b| subject.allow?(&b) }.
            to yield_with_args(nil, nil)
        end

        context 'when the block returns false' do
          it 'raises an AuthenticationError' do
            expect{ subject.allow?{ false } }.
              to raise_error(AuthenticationError)
          end
        end

        context 'when the block returns true' do
          it 'returns true also' do
            output = subject.allow?{ true }
            expect(output).to eq(true)
          end
        end

      end

      context 'when the auth is not valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic xxxx' } }

        it 'raises an AuthenticationError' do
          expect{ subject.allow? }.to raise_error(AuthenticationError)
        end

      end

      context 'when the auth is valid' do

        let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic eDp5' } }

        it 'yields the token and the grantor into the block' do
          expect{ |b| subject.allow?(&b) }.
            to yield_with_args(user.token, user)
        end

        context 'when the block returns false' do
          it 'raises an AuthorizationError' do
            expect{ subject.allow?{ false } }.
              to raise_error(AuthorizationError)
          end
        end

        context 'when the block returns true' do
          it 'returns true also' do
            output = subject.allow?{ true }
            expect(output).to eq(true)
          end
        end

      end

    end

  end

end

