require 'rack_helper'
require_app 'api/v1'

describe 'API routes/cameras' do

  let(:app) { Evercam::APIv1 }

  let(:camera) { create(:camera, is_public: true) }

  let(:token) { create(:access_token) }

  let(:access_right) { create(:camera_access_right, token: token) }

  describe 'presented fields' do

    describe "for public cameras" do
      describe "when not the camera owner" do

        let(:json) {
          output = get("/cameras/#{camera.exid}").json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns a subset the cameras details' do
          expect(json).to have_keys(
            'id', 'name', 'created_at', 'updated_at', 'last_polled_at',
            'is_public', 'is_online', 'last_online_at', 'vendor', 'model',
            'timezone', 'location')
          expect(json).to not_have_keys('owner', 'endpoints', 'snapshots',
                                        'auth', 'mac_address')
        end

      end

      describe "when queried by the camera owner" do
        let(:user) { create(:user, username: 'xxxx', password: 'yyyy') }
        let(:camera) { create(:camera, is_public: true, owner: user) }
        let(:json) {
          env    = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          output = get("/cameras/#{camera.exid}", {}, env).json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns the full camera details' do
          expect(json).to have_keys(
            'id', 'name', 'owner', 'created_at', 'updated_at',
            'last_polled_at', 'is_public', 'is_online', 'last_online_at',
            'endpoints', 'vendor', 'model', 'timezone', 'snapshots', 'auth',
            'location', 'mac_address')
        end
      end

      describe "when queried by someone that is not the camera owner" do
        let(:user1) { create(:user, username: 'aaaa', password: 'bbbb') }
        let(:user2) { create(:user, username: 'xxxx', password: 'yyyy') }
        let(:camera) { create(:camera, is_public: true, owner: user2) }
        let(:json) {
          user1.save
          user2.save
          env    = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('aaaa:bbbb')}" }
          output = get("/cameras/#{camera.exid}", {}, env).json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns s subset of the cameras details' do
          expect(json).to have_keys(
            'id', 'name', 'created_at', 'updated_at', 'last_polled_at',
            'is_public', 'is_online', 'last_online_at', 'vendor', 'model',
            'timezone', 'location')
          expect(json).to not_have_keys('owner', 'endpoints', 'snapshots',
                                        'auth', 'mac_address')
        end
      end
    end

    describe "when location"

      let(:json) {
        output = get("/cameras/#{camera.exid}").json
        output['cameras'] ? output['cameras'][0] : {}
      }

      context 'is nil' do
        it 'returns location as nil' do
          camera.update(location: nil)
          expect(json['location']).to be_nil
        end
      end

      context 'is not nil' do
        it 'returns location as lng lat object' do
          camera.update(location: { lng: 10, lat: 20 })
          expect(json['location']).to have_keys('lng', 'lat')
        end
      end

  end

  describe 'GET /cameras/test' do

    let (:test_params_invalid)  do
      {
        external_url: 'http://1.1.1.1',
        jpg_url: '/test.jpg',
        cam_username: 'aaa',
        cam_password: 'xxx'
      }
    end

    let (:test_params_valid)  do
      {
        external_url: 'http://89.101.225.158:8105',
        jpg_url: '/Streaming/channels/1/picture',
        cam_username: 'admin',
        cam_password: 'mehcam'
      }
    end

    context 'when there are no parameters' do
      it 'returns a 400 bad request status' do
        expect(get('/cameras/test').status).to eq(400)
      end
    end

    context 'when parameters are incorrect' do
      it 'returns a 400 bad request status' do
        VCR.use_cassette('API_cameras/test') do
          expect(get('/cameras/test', test_params_invalid.merge(external_url: '2.2.2.2:123', jpg_url: 'pancake')).status).to eq(400)
        end
      end
    end

    context 'when parameters are correct, but camera is offline' do
      it 'returns a 503 camera offline status' do
        VCR.use_cassette('API_cameras/test') do
          expect(get('/cameras/test', test_params_invalid).status).to eq(503)
        end
      end
    end

    context 'when auth is wrong' do
      it 'returns a 403 status' do
        VCR.use_cassette('API_cameras/test') do
          expect(get('/cameras/test', test_params_valid.merge(cam_password: 'xxx')).status).to eq(403)
        end
      end
    end

    context 'when parameters are correct' do
      it 'returns a 200 status with image data' do
        VCR.use_cassette('API_cameras/test') do
          expect(get('/cameras/test', test_params_valid).status).to eq(200)
        end
      end
    end

  end

  describe 'GET /cameras/:id' do

    context 'when the camera does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/cameras/xxxx').status).to eq(404)
      end
    end

    context 'when the camera is public' do
      it 'returns the camera data' do
        response = get("/cameras/#{camera.exid}")
        expect(response.status).to eq(200)
      end
    end

    context 'when the camera is private' do

      let(:camera) { create(:camera, is_public: false) }

      context 'when the request is unauthenticated' do
        it 'returns an UNAUTHORIZED status' do
          expect(get("/cameras/#{camera.exid}").status).to eq(401)
        end
      end

      context 'when the request is unauthorized' do
        it 'returns a FORBIDDEN status' do
          create(:user, username: 'xxxx', password: 'yyyy')
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/cameras/#{camera.exid}", {}, env).status).to eq(403)
        end
      end

      context 'when the request is authorized' do
        it 'returns the camera data' do
          camera.update(owner: create(:user, username: 'xxxx', password: 'yyyy'))
          env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          expect(get("/cameras/#{camera.exid}", {}, env).status).to eq(200)
        end
      end

    end

    it 'returns the camera make and model information when available' do
      model = create(:firmware)
      camera.update(firmware: model)

      response = get("/cameras/#{camera.exid}")
      data = response.json['cameras'][0]

      expect(data['vendor']).to eq(model.vendor.exid)
      expect(data['model']).to eq(model.name)
    end

    it 'can fetch details for a camera via MAC address' do
      camera.update(owner: create(:user, username: 'xxxx', password: 'yyyy'))
      env = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
      response = get("/cameras/#{camera.mac_address}", {}, env)
      data     = response.json['cameras'][0]

      expect(data['id']).to eq(camera.exid)
      expect(data['mac_address']).to eq(camera.mac_address)
    end

  end

  describe 'POST /cameras' do

    let(:auth) { env_for(session: { user: create(:user).id }) }

    let(:params) {
      {
        id: 'my-new-camera',
        name: "Garrett's Super New Camera",
        endpoints: ['http://localhost:1234'],
        is_public: true
      }.merge(
        build(:camera).config
      )
    }

    context 'when the params are valid' do

      before(:each) do
        post('/cameras', params, auth)
      end

      it 'returns a CREATED status' do
        expect(last_response.status).to eq(201)
      end

      it 'creates a new camera in the system' do
        expect(Camera.first.exid).
          to eq(params[:id])
      end

      it 'returns the new camera' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([Camera.first.exid])
      end

    end

    context 'when required keys are missing' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', { id: '' }, auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when is_public is null' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(is_public: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when :endpoints key is missing' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(endpoints: nil), auth)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHORZIED status' do
        expect(post('/cameras', params).status).to eq(401)
      end
    end

  end

  describe 'PATCH /cameras' do

    let(:camera) { create(:camera, is_public: false, owner: create(:user, username: 'xxxx', password: 'yyyy')) }
    let(:model) { create(:firmware) }

    let(:params) {
      {
        name: "Garrett's Super New Camera v2",
        endpoints: ['http://www.evercam.io', 'http://localhost:4321'],
        is_public: false,
        mac_address: 'aa:aa:aa:aa:aa:aa',
        vendor: model.vendor.exid,
        model: model.name,
        timezone: 'Etc/GMT+1',
        snapshots: { 'jpg' => '/snap'},
        auth: { 'basic' => {'username' => 'zzz', 'password' => 'qqq'}}
      }
    }

    context 'when the params are valid' do

      before do
        camera.add_endpoint({
          scheme: 'http',
          host: 'www.evercam.io',
          port: 80
        })
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        patch("/cameras/#{camera.exid}", params, auth)
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'updates camera in the system' do
        cam = Camera.by_exid(camera.exid)
        expect(cam.is_public).to eq(false)
        expect(cam.name).to eq("Garrett's Super New Camera v2")
        expect(cam.firmware).to eq(model)
        expect(cam.mac_address).to eq('aa:aa:aa:aa:aa:aa')
        expect(cam.timezone.zone).to eq('Etc/GMT+1')
        expect(cam.config['snapshots']).to eq({ 'jpg' => '/snap'})
        expect(cam.config['auth']).to eq({ 'basic' => {'username' => 'zzz', 'password' => 'qqq'}})
        expect(cam.endpoints.length).to eq(2)
        expect(cam.endpoints[1][:port]).to eq(4321)
      end

      it 'returns the updated camera' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera.exid])
      end

    end

    context 'when params are empty' do
      it 'returns a OK status' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        patch("/cameras/#{camera.exid}", params.clear, auth)
        expect(last_response.status).to eq(200)
      end
    end

    context 'when snapshot url doesnt start with slash' do
      it 'returns a OK status' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        patch("/cameras/#{camera.exid}", {snapshots: {jpg: 'image.jpg'}}, auth)
        expect(last_response.json['cameras'][0]['snapshots']['jpg']).to eq('/image.jpg')
        expect(last_response.status).to eq(200)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHORZIED status' do
        expect(patch("/cameras/#{camera.exid}", params).status).to eq(401)
      end
    end

    context 'for a public camera with public shares' do
      let(:camera) { create(:camera, is_public: true, owner: create(:user, username: 'xxxx', password: 'yyyy')) }
      let(:sharer1) { create(:user) }
      let(:sharer2) { create(:user) }
      let(:sharer3) { create(:user) }
      let(:share1) { create(:public_camera_share, user: sharer1, camera: camera) }
      let(:share2) { create(:public_camera_share, user: sharer2, camera: camera) }
      let(:share3) { create(:private_camera_share, user: sharer3, camera: camera) }

      context 'when the camera is switched from being public' do
        before(:each) do
          share1.save
          share2.save
          share3.save
        end

        it "deletes all the public shares but leaves private shares unchanged" do
          auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
          patch("/cameras/#{camera.exid}", params, auth)

          expect(CameraShare.where(camera_id: camera.id,
                                   kind: CameraShare::PUBLIC).count).to eq(0)
          expect(CameraShare.where(camera_id: camera.id,
                                   kind: CameraShare::PRIVATE).count).to eq(1)
        end
      end
    end

  end

  describe 'DELETE /cameras' do

    let(:camera) { create(:camera, is_public: false, owner: create(:user, username: 'xxxx', password: 'yyyy')) }

    context 'when params are empty' do
      it 'returns a OK status' do
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        delete("/cameras/#{camera.exid}", {}, auth)
        expect(last_response.status).to eq(200)
        expect(Camera.by_exid(camera.exid)).to eq(nil)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHORZIED status' do
        expect(delete("/cameras/#{camera.exid}", {}).status).to eq(401)
      end
    end

  end

  describe 'GET /cameras/:id/shares' do
    let(:owner) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:camera) { create(:camera, is_public: false, owner: owner) }

    context "where shares don't exist" do
      let(:shares) {
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        get("/cameras/#{camera.exid}/shares", {}, auth).json['shares']
      }

      it "returns an empty list" do
        expect(shares.size).to eq(0)
      end
    end

    context "where shares exist" do
      let(:sharer1) { create(:user) }
      let(:sharer2) { create(:user) }
      let(:share1) { create(:private_camera_share, camera: camera, user: sharer1) }
      let(:share2) { create(:private_camera_share, camera: camera, user: sharer2) }
      let(:shares) {
        create(:private_camera_share, camera: camera, user: sharer1).save
        create(:private_camera_share, camera: camera, user: sharer2).save
        auth = { 'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}" }
        get("/cameras/#{camera.exid}/shares", {}, auth).json['shares']
      }

      it "returns a full list of shares for a camera" do
        expect(shares.size).to eq(2)
        expect(shares[0]).to have_keys('id', 'camera_id', 'user_id', 'email', 'kind', 'rights')
      end
    end
  end

  describe 'POST /cameras/:id/share' do
    let(:owner) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:sharer) { create(:user) }
    let(:camera) { create(:camera, is_public: false, owner: owner) }
    let(:auth) { env_for(session: { user: owner.id }) }
    let(:parameters) {{email: sharer.email, rights: "Snapshot,List"}}

    context "where an email address is not specified" do
      it "returns an error" do
        parameters.delete(:email)
        response = post("/cameras/#{camera.exid}/share", parameters, auth)
        expect(response.status).to eq(400)
      end
    end

    context "where rights are not specified" do
      it "returns an error" do
        parameters.delete(:rights)
        response = post("/cameras/#{camera.exid}/share", parameters, auth)
        expect(response.status).to eq(400)
      end
    end

    context "where the camera does not exist" do
      it "returns an error" do
        response = post("/cameras/blahblah/share", parameters, auth)
        expect(response.status).to eq(404)
      end
    end

    context "where the user email does not exist" do
      it "returns an error" do
        parameters[:email] = "noone@nowhere.com"
        response = post("/cameras/blah/share", parameters, auth)
        expect(response.status).to eq(404)
      end
    end

    context "where the caller is not the owner of the camera" do
      it "returns an error" do
        settings = env_for(session: { user: create(:user).id })
        response = post("/cameras/#{camera.exid}/share", parameters, settings)
        expect(response.status).to eq(403)
      end
    end

    context "where the invalid rights are requested" do
      it "returns an error" do
        parameters[:rights] = "blah, ningy"
        response = post("/cameras/blah/share", parameters, auth)
        expect(response.status).to eq(404)
      end
    end

    context "when a proper request is sent" do
      it "returns success" do
        response = post("/cameras/#{camera.exid}/share", parameters, auth)
        expect(response.status).to eq(201)
      end
    end    
  end

  describe 'DELETE /cameras/:id/share/:share_id' do
    let(:owner) { create(:user, username: 'xxxx', password: 'yyyy') }
    let(:sharer) { create(:user) }
    let(:camera) { create(:camera, is_public: false, owner: owner) }
    let(:auth) { env_for(session: { user: owner.id }) }

    context "where the share specified does not exist" do
      it "returns success" do
        response = delete("/cameras/#{camera.exid}/share", {share_id: -100}, auth)
        expect(response.status).to eq(200)
      end
    end

    context "when deleting a share that exists" do
      let(:share) { create(:private_camera_share, camera: camera, user: owner, sharer: sharer).save }

      context "where the camera specified does not exist" do
        it "returns a not found" do
          response = delete("/cameras/blahdeblah/share", {share_id: share.id}, auth)
          expect(response.status).to eq(404)
        end
      end

      context "when the caller does not own the camera" do
        it "returns an error" do
          settings = env_for(session: { user: create(:user).id })
          response = delete("/cameras/#{camera.exid}/share", {share_id: share.id}, settings)
          expect(response.status).to eq(403)
        end
      end

      context "when proper request is sent" do
        it "returns success" do
          response = delete("/cameras/#{camera.exid}/share", {share_id: share.id}, auth)
          expect(response.status).to eq(200)
        end
      end
    end
  end

end

