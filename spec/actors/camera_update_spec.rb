require 'data_helper'

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
          external_rtsp_port: 7393,
          internal_rtsp_port: 7292,
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
          external_rtsp_port: 5393,
          internal_rtsp_port: 5292,
          is_public: true,
          jpg_url: '/new/snapshot',
          mjpg_url: '/mjpg',
          h264_url: '/h264',
          audio_url: '/audio',
          mpeg_url: '/mpeg',
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

        it 'checks the camera name has correct length' do
          params = valid.merge(name: 'very long name over 24 characters long')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:name]).to eq(:valid)
        end

        it 'checks any provided location_lng is valid' do
          params = valid.merge(location_lng: 10)

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:location_lat]).to eq(:valid)
        end

        it 'checks any provided location_lat is valid' do
          params = valid.merge(location_lat: 10)

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:location_lng]).to eq(:valid)
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
          expect(result.config['external_rtsp_port']).to eq(new_valid[:external_rtsp_port])
          expect(result.config['internal_rtsp_port']).to eq(new_valid[:internal_rtsp_port])
          expect(result.res_url('jpg')).to eq(new_valid[:jpg_url])
          expect(result.res_url('mjpg')).to eq(new_valid[:mjpg_url])
          expect(result.res_url('h264')).to eq(new_valid[:h264_url])
          expect(result.res_url('audio')).to eq(new_valid[:audio_url])
          expect(result.res_url('mpeg')).to eq(new_valid[:mpeg_url])
          expect(result.is_online).to be true
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

        it 'sets the location value when provided' do
          params = valid.merge(location_lng: 10, location_lat: 20)

          outcome = subject.run(params)
          result = outcome.result
          expect(outcome).to be_success

          expect(result.location.x).to eq(10)
          expect(result.location.y).to eq(20)
        end

        it 'sets the is_online value when provided' do
          params = valid.merge(is_online: false)

          outcome = subject.run(params)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.is_online).to be false
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

      describe 'updating the discoverable attribute' do
        let(:parameters) {
          {id: camera.exid, discoverable: true}
        }

        it 'set discoverable to true when given true as a discoverable parameter' do
          outcome = subject.run(parameters)
          camera.reload
          expect(camera.discoverable?).to eq(true)
        end

        it 'set discoverable to false when given false as a discoverable parameter' do
          parameters[:discoverable] = false
          outcome = subject.run(parameters)
          camera.reload
          expect(camera.discoverable?).to eq(false)
        end
      end

      describe 'when is_public' do
        before(:each) {
          camera.update(is_public: true)
        }

        describe 'is not specified in the request' do
          let(:parameters) {
            {id: camera.exid, external_host: "178.211.45.121"}
          }

          it 'does not change the cameras is_public setting' do
            outcome = subject.run(parameters)
            camera.reload
            expect(camera.is_public?).to eq(true)
          end
        end

        describe 'is specified in the request' do
          let(:parameters) {
            {id: camera.exid, external_host: "178.211.45.121", is_public: false}
          }

          it 'does change the cameras is_public setting' do
            outcome = subject.run(parameters)
            camera.reload
            expect(camera.is_public?).to eq(false)
          end
        end
      end

    end

  end
end

