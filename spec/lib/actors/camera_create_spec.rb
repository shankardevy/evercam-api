require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe CameraCreate do

      let(:valid) do
        {
          id: 'my-new-camera',
          name: 'My Fancy New Camera',
          username: create(:user).username,
          endpoints: ['http://127.0.0.1:9393'],
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
          params = valid.merge(id: create(:camera).exid)

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
          expect(errors[:endpoints]).to eq(:valid)
        end

        it 'checks that endpoints is actually an array' do
          params = valid.merge(endpoints: 'xxxx')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:endpoints]).to eq(:valid)
        end

        it 'checks each endpoint is a valid uri' do
          params = valid.merge(endpoints: ['h'])

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:endpoints]).to eq(:valid)
        end

        it 'checks any provided timezone is valid' do
          params = valid.merge(timezone: 'BADZONE')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:timezone]).to eq(:valid)
        end

      end

      describe 'optional params' do

        it 'sets the timezone value when provided' do
          timezone = Timezone::Zone.new zone: 'America/Chicago'
          params = valid.merge(timezone: timezone.zone)

          outcome = subject.run(params)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.timezone).to eq(timezone)
        end

      end

      context 'when it creates a camera' do
        it 'fires off a dns upsert worker' do
          params = valid

          Evercam::DNSUpsertWorker.expects(:perform_async).
            with('my-new-camera', '127.0.0.1')

          outcome = subject.run(params)
          expect(outcome).to be_success
        end
      end

    end

  end
end

