require 'data_helper'

describe CameraActivity do

  subject { CameraActivity }

  describe '#to_s' do

    let(:camera0) { create(:camera, name: 'Test Camera') }
    let(:user0) { create(:user, forename: 'Tomasz', lastname: 'Jama') }

    it 'returns human readable string' do
      time = Time.now
      activity0 = subject.new(camera: camera0, user: user0,
                              action: 'Test', done_at: time)
      expect(activity0.to_s).to eq('[Test Camera] Tomasz Jama Test ' + time.to_s)
    end

  end

end