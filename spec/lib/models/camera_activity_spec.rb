require 'data_helper'
require 'rack_helper'
require_app 'api/v1'


describe CameraActivity do

  subject { CameraActivity }

  let(:app) { Evercam::APIv1 }

  describe '#to_s' do

    let(:camera0) { create(:camera, name: 'Test Camera') }
    let(:user0) { create(:user, forename: 'Tomasz', lastname: 'Jama') }
    let(:at0) { create(:access_token, user: user0) }
    let(:time) {Time.now}

    it 'returns human readable string for normal user' do
      activity0 = subject.new(camera: camera0, access_token: at0,
                              action: 'Test', done_at: time, ip: '1.1.1.1')
      expect(activity0.to_s).to eq("[#{camera0.exid}] Tomasz Jama Test at #{time.to_s} from #{activity0.ip}")
    end

    it 'returns human readable string for anonymous user' do
      activity0 = subject.new(camera: camera0, access_token: nil,
                              action: 'Test', done_at: time, ip: '1.1.1.1')
      expect(activity0.to_s).to eq("[#{camera0.exid}] Anonymous Test at #{time.to_s} from #{activity0.ip}")
    end

  end

  describe 'public camera access' do

    let(:camera0) { create(:camera, is_public: true) }

    context 'when the request is unauthorized' do
      it 'creates anonymous access activity' do
        # TODO - think about logs
        #response = get("/cameras/#{camera0.exid}")
        #expect(response.status).to eq(200)
        #ca = CameraActivity.first
        #expect(ca.camera.exid).to eq(camera0.exid)
        #expect(ca.access_token).to eq(nil)
        #expect(ca.action).to eq('accessed')
        #expect(ca.ip).to eq('127.0.0.1')
      end
    end

    let(:auth) { {api_id: camera0.owner.api_id, api_key: camera0.owner.api_key} }

    context 'when the request is authorized' do
      it 'creates access activity' do
        expect(get("/cameras/#{camera0.exid}", auth).status).to eq(200)
        ca = CameraActivity.first
        expect(ca.camera.exid).to eq(camera0.exid)
        expect(ca.access_token).to eq(camera0.owner.token)
        expect(ca.action).to eq('accessed')
        expect(ca.ip).to eq('127.0.0.1')
      end
    end

  end

  describe 'camera edit' do

    let(:camera) { create(:camera, owner: create(:user, username: 'xxxx', password: 'yyyy')) }

    let(:params) {
      {
        name: "Garrett's Super New Camera v2",
        is_public: true,
        api_id: camera.owner.api_id,
        api_key: camera.owner.api_key
      }
    }

    context 'when new camera is created' do
      it 'creates create activity' do
        response = patch("/cameras/#{camera.exid}", params)
        expect(response.status).to eq(200)
        ca = CameraActivity.first
        expect(ca.camera.exid).to eq(Camera.first.exid)
        expect(ca.access_token).to eq(Camera.first.owner.token)
        expect(ca.action).to eq('edited')
      end
    end

  end

end