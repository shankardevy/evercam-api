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
          external_host: '123.0.0.1',
          internal_host: '127.0.0.1',
          external_http_port: 9393,
          internal_http_port: 9292,
          is_public: true,
          jpg_url: '/onvif/snapshot',
          cam_username: 'admin',
          cam_password: '12345'
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

        it 'checks external_host is a valid uri' do
          params = valid.merge(external_host: '!h')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:external_host]).to eq(:valid)
        end

        it 'checks internal_host is a valid uri' do
          params = valid.merge(internal_host: '!h')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:internal_host]).to eq(:valid)
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
          outcome = subject.run(valid)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.config['external_host']).to eq(valid[:external_host])
          expect(result.config['internal_host']).to eq(valid[:internal_host])
          expect(result.config['external_http_port']).to eq(valid[:external_http_port])
          expect(result.config['internal_http_port']).to eq(valid[:internal_http_port])
          expect(result.jpg_url).to eq(valid[:jpg_url])
          expect(result.cam_username).to eq(valid[:cam_username])
          expect(result.cam_password).to eq(valid[:cam_password])
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
            with(valid[:id], valid[:external_host])

          outcome = subject.run(params)
          expect(outcome).to be_success
        end
      end

    end

  end
end

