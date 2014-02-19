require 'rack_helper'
require_app 'api/v1'

describe 'API routes/snapshots', :focus => true do


  let(:app) { Evercam::APIv1 }

  let(:camera0) { create(:camera_endpoint, host: '89.101.225.158', port: 8101).camera }

  describe 'POST /cameras/:id/snapshots' do

    let(:auth) { env_for(session: { user: camera0.owner.id }) }

    let(:params) {
      {
        notes: 'Snap note'
      }
    }

    context 'when snapshot request is correct' do
      it 'snapshot is saved to database' do
        VCR.use_cassette('API_snapshots/basic_post') do
          post("/cameras/#{camera0.exid}/snapshots", params, auth)
          expect(last_response.status).to eq(201)
          snap = Snapshot.first
          expect(snap.notes).to eq('Snap note')
          expect(snap.camera).to eq(camera0)
        end
      end
    end

  end

end
