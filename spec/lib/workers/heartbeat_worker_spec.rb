require 'spec_helper'
require_lib 'workers'

describe Evercam::HeartBeatWorker, :focus => true do

  subject { Evercam::HeartBeatWorker }

  it 'updates online status' do
    stub_request(:any, 'www.evercam.test')
    endpoint0 = create(:camera_endpoint)
    Camera.any_instance.
      expects(:update).with() { |h| h[:is_online] && h[:polled_at] && h[:last_online_at]}

    subject.new.perform(endpoint0.camera_id)
  end

  it 'updates offline status' do
    endpoint0 = create(:camera_endpoint)
    Camera.any_instance.
      expects(:update).with() { |h| h[:is_online] == false && h[:polled_at] && !h.has_key?('last_online_at')}

    subject.new.perform(endpoint0.camera_id)
  end

end
