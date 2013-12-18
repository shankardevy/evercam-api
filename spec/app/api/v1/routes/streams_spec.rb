require 'rack_helper'
require_app 'api/v1'

describe 'API routes/streams' do

  let(:app) { Evercam::APIv1 }

  let(:auth) { env_for(session: { user: create(:user).id }) }

  let(:params) do
    {
      id: 'my-new-stream',
      endpoints: ['http://localhost:9393'],
      is_public: true,
      snapshots: {
        jpg: '/onvif/snapshot'
      },
      auth: {
        basic: {
          username: 'admin',
          password: '12345'
        }
      }
    }
  end

  describe 'POST /streams' do

    context 'when the params are valid' do

      before(:each) do
        post('/streams', params, auth)
      end

      it 'returns a CREATED status' do
        expect(last_response.status).to eq(201)
      end

      it 'creates a new stream in the system' do
        expect(Stream.first.name).to eq(params[:id])
      end

      it 'returns the new stream data' do
        expect(last_response.json['streams'][0].keys).
          to eq(['id', 'owner', 'created_at', 'updated_at',
                 'endpoints', 'is_public', 'snapshots', 'auth'])
      end

    end

    context 'when the params are invalid' do

      before(:each) do
        post('/streams', params.merge(is_public: nil), auth)
      end

      it 'returns a BAD REQUEST status' do
        expect(last_response.status).to eq(400)
      end

      it 'returns the result error messages' do
        expect(last_response.json.keys).to eq(['message'])
      end

    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHROZIED status' do
        expect(post('/streams', params).status).to eq(401)
      end
    end

  end

end

