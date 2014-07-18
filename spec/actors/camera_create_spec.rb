require 'data_helper'

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
          external_rtsp_port: 7393,
          internal_rtsp_port: 7292,
          is_public: true,
          jpg_url: '/onvif/snapshot',
          mjpg_url: '/mjpg',
          h264_url: 'h264',
          audio_url: '/audio',
          mpeg_url: '/mpeg',
          cam_username: 'admin',
          cam_password: '12345'
        }
      end

      subject { CameraCreate }

      describe 'invalid params' do

        it 'checks that the user name is specified' do
          valid.delete(:username)
          outcome = subject.run(valid)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:username]).to eq(:required)
        end

        it 'raises an exception when the username does not exist' do
          params = valid.merge(username: 'xxxx')
          expect {subject.run(params)}.to raise_error(Evercam::NotFoundError, "Unable to locate a user for 'xxxx'.")
        end

        it 'raises an exception when the camera id is already in use' do
          params = valid.merge(id: create(:camera).exid)
          expect {subject.run(params)}.to raise_error(Evercam::ConflictError, "A camera with the id '#{params[:id]}' already exists.")
        end

        it 'detects when a model has been specified but a vendor has not' do
          valid[:model] = 'a_model'
          outcome = subject.run(valid)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:model]).to eq(:valid)
        end

        it 'raises an exception when a vendor is specified and a model is not but the vendor does not possess a default model' do
          vendor         = create(:vendor)
          valid[:vendor] = vendor.exid
          expect {subject.run(valid)}.to raise_error(Evercam::NotFoundError,
                                                     "Unable to locate a default model for the '#{vendor.name}' vendor.")
        end

        it 'raises an exception when the vendor specified does not exist' do
          valid[:vendor] = 'non_existent'
          valid[:model]  = 'non_existent'
          expect {subject.run(valid)}.to raise_error(Evercam::NotFoundError,
                                                     "Unable to locate a vendor for 'non_existent'.")
        end

        it 'raises an exception when the model specified does not exist' do
          vendor         = create(:vendor)
          valid[:vendor] = vendor.exid
          valid[:model]  = 'non_existent'
          expect {subject.run(valid)}.to raise_error(Evercam::NotFoundError,
                                                     "Unable to locate a model for 'non_existent' under the '#{vendor.name}' vendor.")
        end

        it 'raises an exception if neither external or internal hosts are specified' do
          valid.delete(:external_host)
          valid.delete(:internal_host)
          expect {subject.run(valid)}.to raise_error(Evercam::BadRequestError,
                                                     "You must specify internal and/or external host.")
        end

        it 'checks the camera id has correct length' do
          params = valid.merge(id: '123')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:id]).to eq(:valid)
        end

        it 'checks the camera name has correct length' do
          params = valid.merge(name: 'very long name over 24 characters long')

          outcome = subject.run(params)
          errors = outcome.errors.symbolic

          expect(outcome).to_not be_success
          expect(errors[:name]).to eq(:valid)
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
          outcome = subject.run(valid)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.config['external_host']).to eq(valid[:external_host])
          expect(result.config['internal_host']).to eq(valid[:internal_host])
          expect(result.config['external_http_port']).to eq(valid[:external_http_port])
          expect(result.config['internal_http_port']).to eq(valid[:internal_http_port])
          expect(result.config['external_rtsp_port']).to eq(valid[:external_rtsp_port])
          expect(result.config['internal_rtsp_port']).to eq(valid[:internal_rtsp_port])
          expect(result.res_url('jpg')).to eq(valid[:jpg_url])
          expect(result.res_url('mjpg')).to eq(valid[:mjpg_url])
          expect(result.res_url('h264')).to eq('/'+valid[:h264_url])
          expect(result.res_url('audio')).to eq(valid[:audio_url])
          expect(result.res_url('mpeg')).to eq(valid[:mpeg_url])
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

        it 'sets the location value when provided' do
          params = valid.merge(location_lng: 10, location_lat: 20)

          outcome = subject.run(params)
          result = outcome.result
          expect(outcome).to be_success

          expect(result.location.x).to eq(10)
          expect(result.location.y).to eq(20)
        end

        it 'sets the online status when provided' do
          params = valid.merge(is_online: true)

          outcome = subject.run(params)
          result = outcome.result

          expect(outcome).to be_success
          expect(result.is_online).to eq(true)
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

      it 'allows creation with only external host' do
        valid.delete(:internal_host)
        outcome = subject.run(valid)
        expect(outcome).to be_success
      end

      it 'allows creation with only internal host' do
        valid.delete(:external_host)
        outcome = subject.run(valid)
        expect(outcome).to be_success
      end

    end

  end
end

