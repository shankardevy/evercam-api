require 'rack_helper'
require_app 'api/v1'

describe 'APIv1 routes/snapshots' do

  let(:app) { Evercam::APIv1 }

  let(:stream) { create(:stream) }

  describe 'GET /streams/:name/snapshots' do

    context 'when the stream does not exist' do
      it 'returns a NOT FOUND status' do
        get('/streams/xxxx/snapshots')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the stream is public' do

      before(:each) do
        get("/streams/#{stream.name}/snapshots")
      end

      it 'renders with an OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the stream snapshot data as json' do
        expect(last_response.json.keys).
          to eq(['uris', 'formats', 'auth'])
      end

    end

  end

end

