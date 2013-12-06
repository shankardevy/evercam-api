require 'rack_helper'
require_app 'api/v1'

describe 'APIv1 routes/snapshots' do

  let(:app) { Evercam::APIv1 }

  let(:stream) { create(:stream, is_public: true) }

  describe 'GET /streams/:name/snapshots/new' do

    let(:url) { "/streams/#{stream.name}/snapshots/new" }

    context 'when the stream does not exist' do
      it 'returns a NOT FOUND status' do
        get('/streams/xxxx/snapshots/new')
        expect(last_response.status).to eq(404)
      end
    end

    context 'when the stream is public' do
      it 'returns the stream snapshot data' do
        get(url)
        expect(last_response.status).to eq(200)
        expect(last_response.json.keys).
          to eq(['uris', 'formats', 'auth'])
      end
    end

    context 'when the stream is private' do

      before(:each) do
        stream.update(is_public: false)
      end

      context 'when the request does not come with authentication' do
        it 'returns a FORBIDDEN status' do
          get(url)
          expect(last_response.status).to eq(401)
        end
      end

      context 'when the request comes with authentication' do

        context 'when the client is not authorized' do
          it 'returns a FORBIDDEN status' do
            create(:user, username: 'xxxx', password: 'yyyy')
            env = { 'HTTP_AUTHORIZATION' => 'Basic eHh4eDp5eXl5' }

            get(url, {}, env)
            expect(last_response.status).to eq(403)
          end
        end

        context 'when the client is authorized' do
          it 'returns the stream snapshot data' do
            user = create(:user, username: 'xxxx', password: 'yyyy')
            stream.update(owner: user)
            env = { 'HTTP_AUTHORIZATION' => 'Basic eHh4eDp5eXl5' }

            get(url, {}, env)
            expect(last_response.status).to eq(200)
            expect(last_response.json.keys).
              to eq(['uris', 'formats', 'auth'])
          end
        end

      end

    end

  end

end

