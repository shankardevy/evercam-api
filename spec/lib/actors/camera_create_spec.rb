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

      let(:new_valid) do
        {
          id: 'my-new-camera',
          name: 'My Fancy New Camera',
          username: create(:user).username,
          external_url: 'http://123.0.0.1:9393',
          is_public: true,
          snapshot_url: '/onvif/snapshot',
          cam_user: 'admin',
          cam_pass: '12345'
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
          expect(errors[:external_url]).to eq(:valid)
        end

        it 'checks that endpoints is converting single string to array' do
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

        it 'checks each endpoint is a valid uri' do
          params = valid.merge(endpoints: [], external_url: 'x')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:external_url]).to eq(:valid)
        end

        it 'checks any provided timezone is valid' do
          params = valid.merge(timezone: 'BADZONE')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:timezone]).to eq(:valid)
        end

        it 'checks any provided mac is valid' do
          params = valid.merge(mac_address: 'BADMAC')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:mac_address]).to eq(:valid)
        end

      end

      describe 'valid new params' do
        it 'returns success' do
          outcome = subject.run(new_valid)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.endpoints.first.to_s).to eq(new_valid[:external_url])
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

        it 'sets the mac value when provided' do
          mac = '3d:f2:c9:a6:b3:4f'
          params = valid.merge(mac_address: mac)

          outcome = subject.run(params)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.mac_address).to eq(mac)
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

