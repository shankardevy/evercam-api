require 'data_helper'
require_lib 'workers'

describe Evercam::HeartbeatWorker do

  subject { Evercam::HeartbeatWorker }

  let(:camera0) { create(:camera_endpoint, host: 'www.evercam.io', port: 80).camera }

  context 'when the camera has no public endpoints' do
    it 'does not make an outbound request' do
      stub_request(:any, 'localhost')

      camera0.endpoints.first.update(host: 'localhost')
      subject.new.perform(camera0.exid)

      assert_not_requested :any, 'localhost'
    end
  end

  context 'when a camera endpoint cannot be resolved' do
    it 'does not raise an error' do
      camera0.endpoints.first.update(host: 'bad.host')
      expect{ subject.new.perform(camera0.exid) }.to_not raise_error
    end
  end

  context 'when the camera is online' do

    before(:each) do
      stub_request(:any, 'www.evercam.io').to_return(status: 200)
      subject.new.perform(camera0.exid)
      camera0.reload
    end

    it 'sets the camera to be online' do
      expect(camera0.is_online).to eq(true)
    end

    it 'updates the polled_at timestamp' do
      expect(camera0.polled_at).to be_around_now
    end

    it 'updates the last_online_at timestamp' do
      expect(camera0.last_online_at).to be_around_now
    end

  end

  context 'when the camera is offline or unreachable' do

    before(:each) do
      stub_request(:any, 'www.evercam.io').to_raise(Net::OpenTimeout)
      subject.new.perform(camera0.exid)
      camera0.update(last_online_at: nil)
      camera0.reload
    end

    it 'sets the camera to be offline' do
      expect(camera0.is_online).to eq(false)
    end

    it 'updates the polled_at timestamp' do
      expect(camera0.polled_at).to be_around_now
    end

    it 'does not update the last_online_at timestamp' do
      expect(camera0.last_online_at).to be_nil
    end

  end

end
