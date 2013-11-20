require 'rack_helper'
require_lib 'withnail'

module Evercam
  module Withnail
    describe WithAuth do

      subject { WithAuth }

      describe '#has_right?' do

        context 'when no authentication is provided' do

          let(:env) { {} }

          it 'raises an AuthenticationError' do
            expect { subject.new(env).has_right?('xxxx', nil) }.
              to raise_error(AuthenticationError)
          end

        end

        context 'when basic authentication is provided' do

          context 'when the user credentials are not valid' do
            it 'raises an AuthenticationError' do
              env = { 'HTTP_AUTHORIZATION' => 'Basic zzzz' }
              expect { subject.new(env).has_right?('xxxx', nil) }.
                to raise_error(AuthenticationError)
            end
          end

          context 'when the user credentials are valid' do

            before(:each) do
              create(:user, username: 'xxxx', password: 'yyyy')
            end

            context 'when the user does not have the right' do
              it 'return false' do
                env = { 'HTTP_AUTHORIZATION' => 'Basic eHh4eDp5eXl5' }
                resource = double(:resource, :has_right? => false)
                expect(subject.new(env).has_right?('xxxx', resource)).
                  to eq(false)
              end
            end

            context 'when the user does have the right' do
              it 'return true' do
                env = { 'HTTP_AUTHORIZATION' => 'Basic eHh4eDp5eXl5' }
                resource = double(:resource, :has_right? => true)
                expect(subject.new(env).has_right?('xxxx', resource)).
                  to eq(true)
              end
            end

          end

        end

        context 'when a session cookie is provided' do

          let(:user) { create(:user) }

          context 'when the credentials are not valid' do
            it 'raises an AuthenticationError' do
              env = env_for(session: { user: '0' })
              expect { subject.new(env).has_right?('xxxx', nil) }.
                to raise_error(AuthenticationError)
            end
          end

          context 'when the credentials are valid' do

            context 'when the user does not have the right' do
              it 'returns false' do
                env = env_for(session: { user: user.id })
                resource = double(:resource, :has_right? => false)
                expect(subject.new(env).has_right?('xxxx', resource) ).
                  to eq(false)
              end
            end

            context 'whent he user does have the right' do
              it 'returns false' do
                env = env_for(session: { user: user.id })
                resource = double(:resource, :has_right? => true)
                expect(subject.new(env).has_right?('xxxx', resource) ).
                  to eq(true)
              end
            end

          end

        end

        context 'when an access token is provided' do

          let(:env) { { 'HTTP_AUTHORIZATION' => "Bearer #{token.request}" } }

          let(:token) { create(:access_token) }

          context 'when the token does not exist' do
            it 'raises an AuthenticationError' do
              token.delete
              expect { subject.new(env).has_right?('xxxx', nil) }.
                to raise_error(AuthenticationError)
            end
          end

          context 'when the token is invalid' do
            it 'raises an AuthenticationError' do
              token.update(is_revoked: true).save
              expect { subject.new(env).has_right?('xxxx', nil) }.
                to raise_error(AuthenticationError)
            end
          end

          context 'when the token is valid but does not provide the right' do
            it 'returns false' do
              resource = double(:resource, :has_right? => false)
              expect(subject.new(env).has_right?('xxxx', resource)).
                to eq(false)
            end
          end

          context 'when the token is valid and does provide the right' do
            it 'returns false' do
              resource = double(:resource, :has_right? => true)
              expect(subject.new(env).has_right?('xxxx', resource)).
                to eq(true)
            end
          end

        end

      end

    end

  end
end

