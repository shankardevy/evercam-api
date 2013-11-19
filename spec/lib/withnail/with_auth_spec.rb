require 'data_helper'
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

          let(:env) { { 'HTTP_AUTHORIZATION' => 'Basic eHh4eDp5eXl5' } }

          context 'when the credentials are not valid' do
            it 'raises an AuthenticationError' do
              expect { subject.new(env).has_right?('xxxx', nil) }.
                to raise_error(AuthenticationError)
            end
          end

          context 'when the credentials are valid' do

            context 'when the user does not have the right' do
              it 'return false' do
                create(:user, username: 'xxxx', password: 'yyyy')
                resource = double(:resource, :has_right? => false)
                expect(subject.new(env).has_right?('xxxx', resource)).
                  to be_false
              end
            end

            context 'when the user does have the right' do
              it 'return true' do
                create(:user, username: 'xxxx', password: 'yyyy')
                resource = double(:resource, :has_right? => true)
                expect(subject.new(env).has_right?('xxxx', resource)).
                  to be_true
              end
            end

          end

        end

      end

    end

  end
end

