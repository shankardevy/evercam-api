require 'data_helper'
require 'rack_helper'
require_app 'api/v1'


describe CameraActivity, :focus => true do

  subject { CameraActivity }

  let(:app) { Evercam::APIv1 }

  describe '#to_s' do

    let(:camera0) { create(:camera, name: 'Test Camera') }
    let(:user0) { create(:user, forename: 'Tomasz', lastname: 'Jama') }
    let(:at0) { create(:access_token, grantor: user0) }
    let(:time) {Time.now}

    it 'returns human readable string for normal user' do
      activity0 = subject.new(camera: camera0, access_token: at0,
                              action: 'Test', done_at: time)
      expect(activity0.to_s).to eq('[Test Camera] Tomasz Jama Test ' + time.to_s)
    end

    it 'returns human readable string for anonymous user' do
      activity0 = subject.new(camera: camera0, access_token: nil,
                              action: 'Test', done_at: time)
      expect(activity0.to_s).to eq('[Test Camera] Anonymous Test ' + time.to_s)
    end

  end

  describe 'anonymous camera access' do

    let(:camera0) { create(:camera, is_public: true) }

    it 'creates anonymous access activity' do
      response = get("/cameras/#{camera0.exid}")
      expect(response.status).to eq(200)
      ca = CameraActivity.first
      expect(ca.camera.exid).to eq(camera0.exid)
      expect(ca.access_token).to eq(nil)
      expect(ca.action).to eq('accessed')
    end

  end

end