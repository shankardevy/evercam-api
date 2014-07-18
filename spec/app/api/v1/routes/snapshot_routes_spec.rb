require 'rack_helper'
require_app 'api/v1'
require 'webmock/rspec'

describe 'API routes/snapshots' do


  let(:app) { Evercam::APIv1 }

  let(:camera0) do
    camera0 = create(:camera)
    camera0.values[:config].merge!({'external_host' => '89.101.225.158'})
    camera0.values[:config].merge!({'external_http_port' => 8105})
    camera0.save
    camera0
  end
  let(:api_keys) { {api_id: camera0.owner.api_id, api_key: camera0.owner.api_key} }
  let(:snap) { create(:snapshot, camera: camera0) }

  let(:other_user) { create(:user) }
  let(:alt_keys) { {api_id: other_user.api_id, api_key: other_user.api_key} }

  describe('GET /cameras/:id/snapshots') do

    let(:snap1) { create(:snapshot, camera: camera0, created_at: Time.now) }

    context 'when snapshot request is correct' do
      it 'all snapshots for given camera are returned' do
        snap1
        get("/cameras/#{snap.camera.exid}/snapshots", api_keys)
        expect(last_response.status).to eq(200)
        expect(last_response.json['snapshots'].length).to eq(2)
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        get("/cameras/#{snap.camera.exid}/snapshots")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when unauthorized' do
      it 'returns an unauthorized error' do
        get("/cameras/#{snap.camera.exid}/snapshots", alt_keys)
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

  describe 'GET /cameras/:id/snapshots/range' do

    before(:all) do
      @exid     = 'xxx'
      @cam      = create(:camera, exid: @exid)
      @api_keys = {api_id: @cam.owner.api_id, api_key: @cam.owner.api_key}
      data = File.read('spec/resources/snapshot.jpg')
      (1..150).each do |n|
        Snapshot.create(camera: @cam, created_at: Time.at(n), data: data)
      end
    end

    after(:all) do
      username = @cam.owner.username
      Camera.where(:exid => @exid).delete
      User.where(:username => username).delete
    end

    describe 'GET /cameras/:id/snapshots/:year/:month/days' do

      context 'when snapshot request is correct' do
        let(:snapOld) { create(:snapshot, camera: @cam, created_at: Time.new(1970, 01, 17, 0, 0, 0, '+00:00')) }

        it 'returns array of days for given date' do
          snapOld
          get("/cameras/#{@exid}/snapshots/1970/01/days", @api_keys)
          expect(last_response.status).to eq(200)
          expect(last_response.json['days']).to eq([1,17])
        end
      end

      context 'when month is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/snapshots/1970/00/days", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when month is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/snapshots/1970/13/days", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{@exid}/snapshots/1970/01/days")
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when unauthorized' do
        it 'returns an unauthorized error' do
          get("/cameras/#{@exid}/snapshots/1970/01/days", api_keys)
          expect(last_response.status).to eq(403)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthorized")
        end
      end
    end

    describe 'GET /cameras/:id/snapshots/:year/:month/:day/hours' do

      context 'when snapshot request is correct' do
        let(:snapOld) { create(:snapshot, camera: @cam, created_at: Time.new(1970, 01, 01, 17, 0, 0, '+00:00')) }

        it 'returns array of hours for given date' do
          snapOld
          get("/cameras/#{@exid}/snapshots/1970/01/01/hours", @api_keys)
          expect(last_response.status).to eq(200)
          expect(last_response.json['hours']).to eq([0,17])
        end
      end

      context 'when day is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/snapshots/1970/01/00/hours", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when day is incorrect' do
        it 'returns 400 error' do
          get("/cameras/#{@exid}/snapshots/1970/01/41/hours", @api_keys)
          expect(last_response.status).to eq(400)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{@exid}/snapshots/1970/01/01/hours")
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when unauthorized' do
        it 'returns an unauthorized error' do
          get("/cameras/#{@exid}/snapshots/1970/01/01/hours", api_keys)
          expect(last_response.status).to eq(403)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthorized")
        end
      end
    end

    context 'when snapshot request is correct' do
      context 'all snapshots within given range are returned' do

        it 'applies default no data limit' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 1234567890}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(100)
        end

        it 'applies default no data limit and returns second page' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 1234567890, page: 2}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(50)
        end

        it 'applies specified limit' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 1234567890, limit: 15}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(15)
        end

        it 'applies default data limit' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 1234567890, with_data: true}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(10)
        end

        it 'applies specified limit' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 1234567890, with_data: true, limit: 5}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(5)
        end

        it 'returns only two entries' do
          get("/cameras/#{@exid}/snapshots/range", {from: 1, to: 2}.merge(@api_keys))
          expect(last_response.status).to eq(200)
          expect(last_response.json['snapshots'].length).to eq(2)
        end
      end
    end

  end

  describe 'GET /cameras/:id/snapshots/latest' do

    let(:camera1) do
      camera1 = create(:camera, is_public: false)
      camera1.values[:config].merge!({'external_host' => '89.101.225.158'})
      camera1.values[:config].merge!({'external_http_port' => 8105})
      camera1.save
      camera1
    end
    let(:auth) { {api_id: camera1.owner.api_id, api_key: camera1.owner.api_key} }

    context 'when snapshot request is correct but there are no snapshots' do
      it 'empty list is returned' do
        get("/cameras/#{camera1.exid}/snapshots/latest", auth)
        expect(last_response.status).to eq(200)
        expect(last_response.json['snapshots'].length).to eq(0)
      end
    end

    let(:instant) { Time.now }
    let(:snap1) { create(:snapshot, camera: camera0, created_at: instant) }
    let(:snap2) { create(:snapshot, camera: camera0, created_at: instant - 1000) }
    let(:snap3) { create(:snapshot, camera: camera0, created_at: instant + 1000) }
    let(:other_user) { create(:user) }

    context 'when snapshot request is correct' do
      it 'latest snapshot for given camera is returned' do
        snap1
        snap2
        snap3
        get("/cameras/#{snap.camera.exid}/snapshots/latest", api_keys)
        expect(last_response.status).to eq(200)
        expect(last_response.json['snapshots'][0]['created_at']).to eq(snap3.created_at.to_i)
        expect(last_response.json['snapshots'][0]['camera']).to eq(snap3.camera.exid)
        expect(last_response.json['snapshots'][0]['timezone']).to eq('Etc/UTC')
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        get("/cameras/#{camera1.exid}/snapshots/latest")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when not authorized' do
      it 'returns an unauthorized error' do
        get("/cameras/#{snap.camera.exid}/snapshots/latest", {api_id: other_user.api_id, api_key: other_user.api_key})
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

  describe 'GET /cameras/:id/live' do

    context 'when snapshot request is correct' do

      context 'and camera is online' do
        it 'returns snapshot jpg' do
          stub_request(:get, /.*89.101.225.158:8105.*/).
            to_return(:status => 200, :body => "", :headers => {})

          get("/cameras/#{snap.camera.exid}/live", api_keys)
          expect(last_response.status).to eq(200)
        end
      end

      context 'and camera is online and requires basic auth' do
        context 'auth is not provided' do
          it 'returns 403 error' do
            stub_request(:get, /.*89.101.225.158:8105.*/).
              to_return(:status => 401, :body => "", :headers => {})

            snap.camera.values[:config]['snapshots'] = { jpg: '/Streaming/channels/1/picture'};
            snap.camera.values[:config]['auth'] = {};
            snap.camera.save
            get("/cameras/#{snap.camera.exid}/live", api_keys)
            expect(last_response.status).to eq(403)
          end
        end

        context 'auth is provided' do
          it 'returns snapshot jpg' do
            stub_request(:get, /.*89.101.225.158:8105.*/).
              to_return(:status => 200, :body => "", :headers => {})

            snap.camera.values[:config]['snapshots'] =  { jpg: '/Streaming/channels/1/picture'}
            snap.camera.values[:config]['auth'] = {basic: {username: 'admin', password: 'mehcam'}};
            snap.camera.save
            get("/cameras/#{snap.camera.exid}/live", api_keys)
            expect(last_response.status).to eq(200)
          end
        end
      end

      context 'and camera is offline' do
        it '503 error is returned' do
          stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
            to_return(:status => 500, :body => nil, :headers => {})

          response = Typhoeus::Response.new({:return_code => :operation_timedout})
          Typhoeus.stub(/#{camera0.external_url}/).and_return(response)
          get("/cameras/#{snap.camera.exid}/live", api_keys)
          expect(last_response.status).to eq(503)
        end
      end

    end

    context 'when snapshot request is not authorized' do
      it 'request is not authorized' do
        camera0.is_public = false
        camera0.save
        get("/cameras/#{snap.camera.exid}/live")
        expect(last_response.status).to eq(401)
      end
    end

  end

  describe 'GET /cameras/:id/snapshot.jpg' do

    context 'when snapshot request is correct' do
      it 'redirects to snapshot server' do
        get("/cameras/#{snap.camera.exid}/snapshot.jpg")
        expect(last_response.status).to eq(302)
        expect(last_response.location).to start_with("#{Evercam::Config[:snapshots][:url]}#{snap.camera.exid}.jpg?t=")
      end
    end

    context 'when snapshot request is not authorized' do
      it 'request is not authorized' do
        camera0.is_public = false
        camera0.save
        get("/cameras/#{snap.camera.exid}/snapshot.jpg")
        expect(last_response.status).to eq(403)
      end
    end

  end

  describe 'GET /cameras/:id/snapshots/:timestamp' do

    context 'when snapshot request is correct' do

      let(:instant) { Time.now }
      let(:s0) { create(:snapshot, camera: camera0, created_at: instant, data: 'xxx') }
      let(:s1) { create(:snapshot, camera: camera0, created_at: instant+1, data: 'xxx') }
      let(:s2) { create(:snapshot, camera: camera0, created_at: instant+2, data: 'xxx') }

      before do
        s0
        s1
        s2
      end

      context 'range is specified' do
        it 'latest snapshot is returned' do
          get("/cameras/#{camera0.exid}/snapshots/#{s0.created_at.to_i}", {range: 10}.merge(api_keys))
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.json['snapshots'][0]['created_at']).to eq(s2.created_at.to_i)
          expect(last_response.status).to eq(200)
        end
      end

      context 'range is not specified' do
        it 'specific snapshot is returned' do
          get("/cameras/#{camera0.exid}/snapshots/#{s1.created_at.to_i}", api_keys)
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.json['snapshots'][0]['created_at']).to eq(s1.created_at.to_i)
          expect(last_response.json['snapshots'][0]['camera']).to eq(s1.camera.exid)
          expect(last_response.status).to eq(200)
        end
      end

      context 'type is not specified' do
        it 'snapshot without image data is returned' do
          get("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", api_keys)
          expect(last_response.json['snapshots'][0]['data']).to be_nil
          expect(last_response.status).to eq(200)
        end
      end

      context 'type is full' do
        it 'snapshot without image data is returned' do
          get("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", {with_data: 'true'}.merge(api_keys))
          expect(last_response.json['snapshots'][0]['data']).not_to be_nil
          expect(last_response.status).to eq(200)
        end
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          get("/cameras/#{camera0.exid}/snapshots/#{s0.created_at.to_i}", {range: 10})
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when unauthorized' do
        it 'returns an unauthorized error' do
          other_user = create(:user)
          parameters = {range: 10, api_id: other_user.api_id, api_key: other_user.api_key}
          get("/cameras/#{camera0.exid}/snapshots/#{s0.created_at.to_i}", parameters)
          expect(last_response.status).to eq(403)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthorized")
        end
      end

    end

  end

  describe 'POST /cameras/:id/snapshots' do

    let(:params) {
      {
        notes: 'Snap note'
      }
    }

    context 'when snapshot request is correct' do

      it 'returns 200 OK status' do
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/snapshots", params.merge(api_keys))
        expect(last_response.status).to eq(201)
      end

      it 'saves snapshot to database' do
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/snapshots", params.merge(api_keys))
        snap = Snapshot.first
        expect(snap.notes).to eq(params[:notes])
        expect(snap.created_at).to be_around_now
        expect(snap.camera.exid).to eq(camera0.exid)
      end

      it 'returns the snapshot' do
        stub_request(:get, "http://abcd:wxyz@89.101.225.158:8105/onvif/snapshot").
          to_return(:status => 200, :body => "", :headers => {})

        post("/cameras/#{camera0.exid}/snapshots", params.merge(api_keys))
        res = last_response.json['snapshots'][0]
        expect(res['camera']).to eq(camera0.exid)
        expect(res['notes']).to eq(params[:notes])
        expect(Time.at(res['created_at'])).to be_around_now
      end

      context 'when unauthenticated' do
        it 'returns an unauthenticated error' do
          post("/cameras/#{camera0.exid}/snapshots", params)
          expect(last_response.status).to eq(401)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthenticated")
        end
      end

      context 'when unauthorized' do
        let(:camera2) { create(:camera, is_public: false) }

        it 'returns an unauthorized error' do
          parameters = params.merge(api_id: other_user.api_id, api_key: other_user.api_key)
          post("/cameras/#{camera2.exid}/snapshots", parameters)
          expect(last_response.status).to eq(403)
          data = JSON.parse(last_response.body)
          expect(data.include?("message")).to eq(true)
          expect(data["message"]).to eq("Unauthorized")
        end
      end

    end

  end

  describe 'POST /cameras/:id/snapshots/:timestamp' do

    let(:params) {
      {
        notes: 'Snap note',
        data: Rack::Test::UploadedFile.new('spec/resources/snapshot.jpg', 'image/jpeg')
      }
    }

    context 'when snapshot request is correct' do
      it 'snapshot is saved to database' do
        post("/cameras/#{camera0.exid}/snapshots/12345678", params.merge(api_keys))
        expect(last_response.status).to eq(201)
        snap = Snapshot.first
        expect(snap.notes).to eq('Snap note')
        expect(snap.created_at).to be_around_now
        expect(snap.camera.exid).to eq(camera0.exid)
        expect(snap.data).not_to be_nil
      end
    end

    context 'when data has incorrect file format' do
      it 'error is returned' do
        post("/cameras/#{camera0.exid}/snapshots/12345678",
             params.merge(data: Rack::Test::UploadedFile.new('.gitignore', 'text/plain')).merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        post("/cameras/#{camera0.exid}/snapshots/12345678", params)
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when unauthorized' do
      let(:camera3) { create(:camera, is_public: false) }

      it 'returns an unauthorized error' do
        post("/cameras/#{camera3.exid}/snapshots/12345678", params.merge(alt_keys))
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

 describe 'DELETE /cameras/:id/snapshots/:timestamp' do

    context 'when snapshot request is correct' do
      it 'snapshot is deleted' do
        delete("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", api_keys)
        expect(last_response.status).to eq(200)
        expect(Snapshot.first).to be_nil
      end
    end

    context 'when unauthenticated' do
      it 'returns an unauthenticated error' do
        delete("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}")
        expect(last_response.status).to eq(401)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthenticated")
      end
    end

    context 'when unauthorized' do
      it 'returns an unauthorized error' do
        delete("/cameras/#{camera0.exid}/snapshots/#{snap.created_at.to_i}", alt_keys)
        expect(last_response.status).to eq(403)
        data = JSON.parse(last_response.body)
        expect(data.include?("message")).to eq(true)
        expect(data["message"]).to eq("Unauthorized")
      end
    end

  end

end
