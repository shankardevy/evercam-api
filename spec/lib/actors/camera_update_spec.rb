require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe CameraCreate do

      let(:camera) {create(:camera, is_public: false) }

      let(:valid) do
        {
          id: camera.exid,
          name: 'My Fancy New Camera',
          endpoints: ['http://127.0.0.1:9393'],
          is_public: true,
          snapshots: {
            jpg: '/onvif/snapshot'
          },
          auth: {
            basic: {
              username: 'administrator',
              password: '123456'
            }
          }
        }
      end

      let(:new_valid) do
        {
          id: camera.exid,
          name: 'My Super Fancy New Camera',
          external_url: 'http://123.0.0.1:9393',
          internal_url: 'http://127.0.0.1:9345',
          is_public: true,
          jpg_url: '/new/snapshot',
          cam_user: 'admin',
          cam_pass: '12345'
        }
      end

      subject { CameraUpdate }

      describe 'invalid params' do

        it 'checks the camera does not already exist' do
          params = valid.merge(id: 'xxxx')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:camera]).to eq(:exists)
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
          expect(result.endpoints.last.to_s).to eq(new_valid[:internal_url])
          expect(result.config['snapshots']['jpg']).to eq(new_valid[:jpg_url])
          expect(result.config['auth']['basic']['username']).to eq(new_valid[:cam_user])
          expect(result.config['auth']['basic']['password']).to eq(new_valid[:cam_pass])
        end
      end

      describe 'valid old params' do
        it 'returns success' do
          outcome = subject.run(valid)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.endpoints.first.to_s).to eq(valid[:endpoints][0])
          expect(result.config['snapshots']['jpg']).to eq(valid[:snapshots][:jpg])
          expect(result.config['auth']['basic']['username']).to eq(valid[:auth][:basic][:username])
          expect(result.config['auth']['basic']['password']).to eq(valid[:auth][:basic][:password])
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

      context 'when it updates a camera' do
        it 'fires off a dns upsert worker' do
          params = valid

          Evercam::DNSUpsertWorker.expects(:perform_async).
            with(camera.exid, '127.0.0.1')

          outcome = subject.run(params)
          expect(outcome).to be_success
        end
      end

    end

  end
end

