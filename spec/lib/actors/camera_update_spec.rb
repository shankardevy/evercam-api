require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe CameraUpdate do

      let(:camera) {create(:camera, is_public: false) }

      let(:valid) do
        {
          id: camera.exid,
          name: 'My Fancy New Camera',
          username: create(:user).username,
          external_host: '123.0.0.1',
          internal_host: '127.0.0.1',
          external_http_port: 9393,
          internal_http_port: 9292,
          is_public: true,
          jpg_url: '/onvif/snapshot',
          cam_username: 'administrator',
          cam_password: '123456'
        }
      end

      let(:new_valid) do
        {
          id: camera.exid,
          name: 'My Super Fancy New Camera',
          external_host: '123.0.0.2',
          internal_host: '127.0.0.2',
          external_http_port: 7393,
          internal_http_port: 7292,
          is_public: true,
          jpg_url: '/new/snapshot',
          cam_username: 'admin',
          cam_password: '12345'
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

        it 'checks each endpoint is a valid uri' do
          params = valid.merge(external_host: '!h')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:external_host]).to eq(:valid)
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
          expect(result.config['external_host']).to eq(new_valid[:external_host])
          expect(result.config['internal_host']).to eq(new_valid[:internal_host])
          expect(result.config['external_http_port']).to eq(new_valid[:external_http_port])
          expect(result.config['internal_http_port']).to eq(new_valid[:internal_http_port])
          expect(result.jpg_url).to eq(new_valid[:jpg_url])
          expect(result.cam_username).to eq(new_valid[:cam_username])
          expect(result.cam_password).to eq(new_valid[:cam_password])
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
            with(camera.exid, valid[:external_host])

          outcome = subject.run(params)
          expect(outcome).to be_success
        end
      end

    end

  end
end

