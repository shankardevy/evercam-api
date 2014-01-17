require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe CameraCreate do

      let(:valid) do
        {
          id: 'my-new-camera',
          username: create(:user).username,
          endpoints: ['http://localhost:9393'],
          is_public: true,
          snapshots: {
            jpg: '/onvif/snapshot'
          },
          auth: {
            basic: {
              username: 'admin',
              password: '12345'
            }
          }
        }
      end

      subject { CameraCreate }

      describe 'invalid params' do

        it 'checks the username exists' do
          params = valid.merge(username: 'xxxx')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:username]).to eq(:exists)
        end

        it 'checks the camera does not already exist' do
          params = valid.merge(id: create(:camera).name)

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:camera]).to eq(:exists)
        end

        it 'checks at least one endpoint is provided' do
          params = valid.merge(endpoints: [])

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:endpoints]).to eq(:size)
        end

      end

    end

  end
end

