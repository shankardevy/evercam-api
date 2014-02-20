require 'rack_helper'
require_app 'api/v1'

describe 'API routes/snapshots', :focus => true do


  let(:app) { Evercam::APIv1 }

  let(:camera0) { create(:camera_endpoint, host: '89.101.225.158', port: 8101).camera }


  describe 'GET /cameras/:id/snapshots' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }
    let(:snap) { create(:snapshot, camera: camera0) }
    let(:snap1) { create(:snapshot, camera: camera0, created_at: Time.now) }

    context 'when snapshot request is correct' do
      it 'all snapshots for given camera are returned' do
        snap1
        get("/cameras/#{snap.camera.exid}/snapshots", {}, auth)
        expect(last_response.status).to eq(200)
        expect(last_response.json['snapshots'].length).to eq(2)
      end
    end

  end
  describe 'GET /cameras/:id/snapshots/:timestamp' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }
    let(:snap) { create(:snapshot, camera: camera0) }

    context 'when snapshot request is correct' do
      it 'snapshot is returned' do
        get("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", {}, auth)
        expect(last_response.status).to eq(200)
      end
    end

  end

  describe 'POST /cameras/:id/snapshots' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }

    let(:params) {
      {
        notes: 'Snap note'
      }
    }

    context 'when snapshot request is correct' do

      before do
        VCR.use_cassette('API_snapshots/basic_post') do
          post("/cameras/#{camera0.exid}/snapshots", params, auth)
        end
      end

      it 'returns 200 OK status' do
        expect(last_response.status).to eq(201)
      end

      it 'saves snapshot to database' do
        snap = Snapshot.first
        expect(snap.notes).to eq(params[:notes])
        expect(snap.created_at).to be_around_now
        expect(snap.camera).to eq(camera0)
      end

      it 'returns the snapshot' do
        res = last_response.json['snapshots'][0]
        expect(res['camera']).to eq(camera0.exid)
        expect(res['notes']).to eq(params[:notes])
        expect(Time.at(res['created_at'])).to be_around_now
      end

    end

  end

  describe 'POST /cameras/:id/snapshots/:timestamp' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }

    let(:params) {
      {
        notes: 'Snap note',
        data: Rack::Test::UploadedFile.new('spec/resources/snapshot.jpg', 'image/jpeg')
      }
    }

    context 'when snapshot request is correct' do
      it 'snapshot is saved to database' do
        # TODO - file upload test
        #post("/cameras/#{camera0.exid}/snapshots/12345678", params, auth)
        #puts last_response.body
        #expect(last_response.status).to eq(201)
        #snap = Snapshot.first
        #expect(snap.notes).to eq('Snap note')
        #expect(snap.created_at).to be_around_now
        #expect(snap.camera).to eq(camera0)
      end
    end

  end

 describe 'DELETE /cameras/:id/snapshots/:timestamp' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }

    let(:snap) { create(:snapshot, camera: camera0) }

    context 'when snapshot request is correct' do
      it 'snapshot is deleted' do
        delete("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", {}, auth)
        expect(last_response.status).to eq(200)
        expect(Snapshot.first).to be_nil
      end
    end

  end

end
