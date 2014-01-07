require 'rack_helper'
require_app 'api/v1'

describe 'API routes/streams' do

  let(:app) { Evercam::APIv1 }

  describe 'GET /streams' do

    let(:stream) { create(:stream, is_public: true) }

    context 'when the stream does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/streams/xxxx').status).to eq(404)
      end
    end

    context 'when the stream is public' do
      it 'returns the stream data' do
        response = get("/streams/#{stream.name}")
        expect(response.status).to eq(200)
      end
    end

    context 'when the stream is private' do

      let(:stream) { create(:stream, is_public: false) }

      context 'when the request is unauthenticated' do
        it 'returns an UNAUTHORIZED status' do
          expect(get("/streams/#{stream.name}").status).to eq(401)
        end
      end

      context 'when the request is unauthorized' do
        it 'returns a FORBIDDEN status' do
          create(:user, username: 'xxxx', password: 'yyyy')
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/streams/#{stream.name}", {}, env).status).to eq(403)
        end
      end

      context 'when the request is authorized' do
        it 'returns the stream data' do
          stream.update(owner: create(:user, username: 'xxxx', password: 'yyyy'))
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/streams/#{stream.name}", {}, env).status).to eq(200)
        end
      end

    end

    it 'returns all the stream data keys' do
      response = get("/streams/#{stream.name}")
      expect(response.json['streams'][0]).to include_keys(
        'id', 'created_at', 'updated_at', 'is_public',
        'endpoints', 'snapshots', 'auth')
    end

  end

  describe 'POST /streams' do

    let(:auth) { env_for(session: { user: create(:user).id }) }

    let(:params) {
      {
        id: 'my-new-stream',
        is_public: true
      }.merge(
        build(:stream).config
      )
    }

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

      it 'returns the new stream data keys' do
        expect(last_response.json['streams'][0]).to include_keys(
          'id', 'created_at', 'updated_at', 'is_public',
          'endpoints', 'snapshots', 'auth')
      end

    end

    context 'when is_public is null' do
      it 'returns a BAD REQUEST status' do
        post('/streams', params.merge(is_public: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when :endpoints key is missing' do
      it 'returns a BAD REQUEST status' do
        post('/streams', params.merge(endpoints: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHROZIED status' do
        expect(post('/streams', params).status).to eq(401)
      end
    end

  end

end

