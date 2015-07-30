require 'rack_helper'
require_app 'api/v1'

describe 'API routes/cameras' do

  let(:app) { Evercam::APIv1 }

  let(:camera_owner) { create(:user) }
  let(:camera) { create(:camera, is_public: true, owner: camera_owner) }

  let(:token) { create(:access_token) }

  let(:access_right) { create(:camera_access_right, token: token) }

  let(:authorization_user) { create(:user) }
  let(:authorization_env) { {'HTTP_AUTHORIZATION' => "Basic #{Base64.encode64('xxxx:yyyy')}"} }
  let(:api_keys) { {api_id: authorization_user.api_id, api_key: authorization_user.api_key} }

  describe 'presented fields' do
    describe "for public cameras" do
      describe "when not the camera owner" do

        let(:json) {
          output = get("/cameras/#{camera.exid}", api_keys).json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns a subset the cameras details' do
          expect(json).to have_keys(
            'id', 'name', 'owned', 'owner', 'vendor_id', 'vendor_name', 'model_id', 'model_name',
            'created_at', 'updated_at', 'last_polled_at', 'last_online_at',
            'timezone', 'is_public', 'is_online', 'discoverable', 'location',
            'proxy_url', 'rights')
          expect(json).to not_have_keys('external', 'internal', 'snapshots',
                                        'auth', 'mac_address', 'dyndns')
        end

      end

      describe "when queried by the camera owner" do
        let(:camera) { create(:camera, is_public: true, owner: authorization_user) }
        let(:json) {
          output = get("/cameras/#{camera.exid}", api_keys).json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns the full camera details' do
          expect(json).to have_keys(
            'id', 'name', 'owned', 'owner', 'vendor_id', 'vendor_name', 'model_id', 'model_name',
            'created_at', 'updated_at', 'last_polled_at', 'last_online_at',
            'timezone', 'is_public', 'is_online', 'discoverable', 'location',
            'external', 'internal','dyndns', 'proxy_url', 'rights')
        end

        it 'indicates that the owner has full rights' do
          rights = json["rights"].split(",")
          expect(rights.length).to eq(AccessRight::BASE_RIGHTS.length * 2)
          AccessRight::BASE_RIGHTS.each do |right|
            expect(rights.include?(right)).to eq(true)
            expect(rights.include?("#{AccessRight::GRANT}~#{right}")).to eq(true)
          end
        end
      end

      describe "when queried by someone that is not the camera owner" do
        let(:not_owner) { create(:user, username: 'aaaa', password: 'bbbb') }
        let(:json) {
          parameters = {api_id: not_owner.api_id, api_key: not_owner.api_key}
          output = get("/cameras/#{camera.exid}", parameters).json
          output['cameras'] ? output['cameras'][0] : {}
        }

        it 'returns s subset of the cameras details' do
          expect(json).to have_keys(
            'id', 'name', 'owned', 'owner', 'vendor_id', 'vendor_name', 'model_id', 'model_name',
            'created_at', 'updated_at', 'last_polled_at', 'last_online_at',
            'timezone', 'is_public', 'is_online', 'discoverable', 'location',
            'proxy_url', 'rights')
          expect(json).to not_have_keys('external', 'internal', 'snapshots',
                                        'auth', 'mac_address', 'dyndns')
        end

        it 'indicates that the user has minimal rights' do
          rights = json["rights"].split(",")
          expect(rights.length).to eq(2)
          expect(rights.include?(AccessRight::LIST)).to eq(true)
          expect(rights.include?(AccessRight::SNAPSHOT)).to eq(true)
        end
      end

      describe "when location" do
        context 'is nil' do
          it 'returns location as nil' do
            camera.update(location: nil)
            json = get("/cameras/#{camera.exid}", api_keys).json
            json = json['cameras'] ? json['cameras'][0] : {}
            expect(json['location']['lng']).to eq(0)
            expect(json['location']['lat']).to eq(0)
          end
        end

        context 'is not nil' do
          it 'returns location as lng lat object' do
            camera.update(location: { lng: 10, lat: 20 })
            authorization_user.save
            json = get("/cameras/#{camera.exid}", api_keys).json
            json = json['cameras'] ? json['cameras'][0] : {}
            expect(json['location']['lng']).to eq(10)
            expect(json['location']['lat']).to eq(20)
          end
        end
      end

      describe "when preview" do
        context 'is nil' do
          it 'returns preview as empty string' do
            camera.update(preview: nil)
            json = get("/cameras/#{camera.exid}?thumbnail=true", api_keys).json
            json = json['cameras'] ? json['cameras'][0] : {}
            expect(json['thumbnail']).to eq("")
          end
        end

        context 'is not nil' do
          it 'returns base 64 encoded camera preview' do
            camera.update(preview: 'aaa')
            json = get("/cameras/#{camera.exid}?thumbnail=true", api_keys).json
            json = json['cameras'] ? json['cameras'][0] : {}
            expect(json['thumbnail']).to_not be_nil
            expect(json['thumbnail']).to start_with('data:image/jpeg;base64,')
          end
        end

        context 'is not requested' do
          it 'returns camera object without thumbnail key' do
            camera.update(preview: 'aaa')
            json = get("/cameras/#{camera.exid}", api_keys).json
            json = json['cameras'] ? json['cameras'][0] : {}
            expect(json).to not_have_keys('thumbnail')
          end
        end
      end

    end
  end

  describe 'POST /cameras/test' do
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
        post('/cameras/test', api_keys)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when parameters are incorrect' do
      it 'returns a 400 bad request status' do
        parameters = test_params_invalid.merge(external_url: '2.2.2.2:123',
                                               jpg_url: 'pancake').merge(api_keys)
        post('/cameras/test', parameters)
        expect(last_response.status).to eq(400)
      end
    end

    context 'when parameters are correct, but camera is offline' do
      it 'returns a 503 camera offline status' do
        stub_request(:get, "http://1.1.1.1/test.jpg").
          to_return(:status => 500, :body => "", :headers => {})

        parameters = test_params_invalid.merge(api_keys)
        post('/cameras/test', parameters)
        expect(last_response.status).to eq(503)
      end
    end

    context 'when auth is wrong' do
      it 'returns a 403 status' do
        stub_request(:get, /.*89.101.225.158:8105.*/).
          to_return(:status => 401, :body => "", :headers => {})

        parameters = test_params_valid.merge(cam_password: 'xxx').merge(api_keys)
        post('/cameras/test', parameters)
        expect(last_response.status).to eq(403)
      end
    end

    context 'when parameters are correct' do
      it 'returns a 200 status with image data' do
        stub_request(:get, /.*89.101.225.158:8105.*/).
          to_return(:status => 200, :body => "", :headers => {})

        parameters = test_params_valid.merge(api_keys)
        post('/cameras/test', parameters)
        expect(last_response.status).to eq(201)
      end
    end

  end

  describe 'GET /cameras/:id' do

    before(:each) {authorization_user.save}

    context 'when the camera does not exist' do
      it 'returns a NOT FOUND status' do
        expect(get('/cameras/xxxx', api_keys).status).to eq(404)
      end
    end

    context 'when the camera is public' do
      context 'and the user is not authenticated' do
        it 'returns the camera data' do
          response = get("/cameras/#{camera.exid}")
          expect(response.status).to eq(200)
        end
      end

      context 'and the user is authenticated' do
        it 'returns the camera data' do
          response = get("/cameras/#{camera.exid}", api_keys)
          expect(response.status).to eq(200)
        end
      end
    end

    context 'when the camera is private' do

      let(:camera) { create(:camera, is_public: false) }

      context 'when the request is unauthenticated' do
        it 'returns an NOT FOUND status' do
          expect(get("/cameras/#{camera.exid}").status).to eq(404)
        end
      end

      context 'when the request is unauthorized' do
        it 'returns a NOT FOUND status' do
          expect(get("/cameras/#{camera.exid}", api_keys).status).to eq(404)
        end
      end

      context 'when the request is authorized' do
        it 'returns the camera data' do
          camera.update(owner: authorization_user)
          expect(get("/cameras/#{camera.exid}", api_keys).status).to eq(200)
        end
      end

    end

    it 'returns the camera make and model information when available' do
      model = create(:vendor_model)
      camera.update(vendor_model: model)

      response = get("/cameras/#{camera.exid}", api_keys)
      data = response.json['cameras'][0]

      expect(data['vendor_id']).to eq(model.vendor.exid)
      expect(data['model_id']).to eq(model.exid)
      expect(data['model_name']).to eq(model.name)
    end

    context 'when data is not complete' do
      let(:camera) { create(:camera, owner: authorization_user) }

      it 'returns null or valid partial url' do
        camera.values[:config].merge!({'external_http_port' =>  '123', 'external_host' => ''})
        camera.values[:config].merge!({'internal_rtsp_port' =>  '', 'internal_host' => '1.1.1.1', 'snapshots' => {'h264' =>'/h264'}})
        camera.save
        response = get("/cameras/#{camera.exid}", api_keys)
        data     = response.json['cameras'][0]
        expect(data['external']['http']['jpg']).to eq("")
        expect(data['proxy_url']['jpg']).to eq("http://evr.cm/#{camera.exid}.jpg")
        expect(data['dyndns']['rtsp']['h264']).to eq("rtsp://#{camera.exid}.evr.cm/h264")
        expect(data['internal']['rtsp']['h264']).to eq('rtsp://1.1.1.1/h264')
        expect(data['internal']['rtsp']['port']).to eq("")
        # expect(data['proxy_url']['hls']).to eq("")
        expect(data['proxy_url']['rtmp']).to eq("")
      end

      it 'returns null or valid partial url' do
        camera.values[:config].merge!({'external_http_port' =>  '123', 'external_host' => ''})
        camera.values[:config].merge!({'internal_rtsp_port' =>  '', 'internal_host' => '1.1.1.1', 'snapshots' => {'h264' =>''}})
        camera.save
        response = get("/cameras/#{camera.exid}", api_keys)
        data     = response.json['cameras'][0]
        expect(data['external']['http']['jpg']).to eq("")
        expect(data['proxy_url']['jpg']).to eq("http://evr.cm/#{camera.exid}.jpg")
        expect(data['dyndns']['rtsp']['h264']).to eq("")
        expect(data['internal']['rtsp']['h264']).to eq("")
        expect(data['internal']['rtsp']['port']).to eq("")
      end
    end

  end

  describe 'POST /cameras' do

    let(:auth) { env_for(session: { user: create(:user).id }) }
    let(:vendor) { create(:vendor)}
    let(:vendor_model) { create(:vendor_model, name: VendorModel::DEFAULT)}

    let(:params) {
      {
        id: 'my-new-camera',
        name: "Super New Camera",
        external_host: 'super.camera',
        internal_host: '192.168.1.101',
        internal_rtsp_port: 9101,
        external_rtsp_port: 8300,
        internal_http_port: 9101,
        external_http_port: 8300,
        vendor: vendor_model.vendor.exid,
        is_public: true
      }.merge(
        build(:camera).config
      )
    }

    let(:params_blank) {
      {
        id: 'my-new-camera',
        name: "Super New Camera",
        external_host: '',
        internal_host: '',
        internal_rtsp_port: '',
        external_rtsp_port: '',
        internal_http_port: '',
        external_http_port: '',
        cam_username: '',
        cam_password: '',
        vendor: '',
        model: '',
        is_public: true
      }
    }

    context 'when the params are valid' do

      before(:each) do
        post('/cameras', params.merge(api_keys))
      end

      it 'returns a CREATED status' do
        skip
        expect(last_response.status).to eq(201)
      end

      it 'creates a new camera in the system' do
        camera = Camera.by_exid('my-new-camera')
        expect(camera.exid).
          to eq(params[:id])
      end

      it 'returns the new camera' do
        skip
        res = last_response.json['cameras'][0]
        expect(res['id']).to eq(Camera.first.exid)
        expect(res['name']).to eq(Camera.first.name)
        expect(res['external']['host']).to eq(Camera.first.config['external_host'])
        expect(res['internal']['host']).to eq(Camera.first.config['internal_host'])
        expect(res['internal']['rtsp']['port']).to eq(Camera.first.config['internal_rtsp_port'])
        expect(res['external']['rtsp']['port']).to eq(Camera.first.config['external_rtsp_port'])
        expect(res['vendor_id']).to eq(Camera.first.vendor.exid)
      end

    end

    context 'when optional fields are blank' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params_blank.merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when vendor doesnt have default model' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(api_keys).merge({vendor: vendor.exid}))
        expect(last_response.status).to eq(404)
        data = last_response.json
        expect(data["code"]).to eq("model_not_found_error")
      end
    end

    context 'when required keys are missing' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', { id: '' }.merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when is_public is invalid' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(is_public: 'Asfdg').merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when name is too long' do
      it 'returns a BAD REQUEST status' do
        post('/cameras', params.merge(name: 'super long camera name over 21 characters').merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when :external_url key is missing' do
      it 'returns a ok status' do
        skip
        post('/cameras', params.merge(external_url: nil).merge(api_keys), auth)
        expect(last_response.status).to eq(201)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHORZIED status' do
        expect(post('/cameras', params).status).to eq(401)
      end
    end

    context 'when authentication details tie to a client rather than a user' do
      it 'returns a BAD REQUEST status' do
        client = create(:client).save
        expect(post('/cameras', params.merge(api_id: client.api_id, api_key: client.api_key)).status).to eq(400)
      end
    end

  end

  describe 'PATCH /cameras' do

    let(:camera) { create(:camera, is_public: false, owner: authorization_user) }
    let(:model) { create(:vendor_model) }

    let(:params) {
      {
        name: "Super New Camera v2",
        external_host: 'www.evercam.io',
        internal_host: 'localhost',
        internal_http_port: 4321,
        is_public: false,
        mac_address: 'aa:aa:aa:aa:aa:aa',
        vendor: model.vendor.exid,
        model: model.exid,
        timezone: 'Etc/GMT+1',
        jpg_url: '/snap',
        cam_username: 'zzz',
        cam_password: 'qqq'
      }
    }

    let(:params_blank) {
      {
        name: "Super New Camera",
        external_host: '',
        internal_host: '',
        internal_rtsp_port: '',
        external_rtsp_port: '',
        internal_http_port: '',
        external_http_port: '',
        mac_address: '',
        cam_username: '',
        cam_password: '',
        vendor: '',
        model: '',
        location_lat: '',
        location_lng: '',
        jpg_url: ''
      }
    }

    context 'when the params are valid' do

      before do
        camera.add_endpoint({
          scheme: 'http',
          host: 'www.evercam.io',
          port: 80
        })
        patch("/cameras/#{camera.exid}", params.merge(api_keys))
      end

      it 'returns a OK status' do
        expect(last_response.status).to eq(200)
      end

      it 'updates camera in the system' do
        cam = Camera.by_exid(camera.exid)
        expect(cam.is_public).to eq(params[:is_public])
        expect(cam.name).to eq(params[:name])
        expect(cam.vendor_model).to eq(model)
        expect(cam.mac_address).to eq(params[:mac_address])
        expect(cam.timezone.zone).to eq('Etc/GMT+1')
        expect(cam.res_url('jpg')).to eq(params[:jpg_url])
        expect(cam.cam_username).to eq(params[:cam_username])
        expect(cam.cam_password).to eq(params[:cam_password])
        expect(cam.external_url).to eq('http://www.evercam.io')
        expect(cam.internal_url).to eq('http://localhost:4321')
      end

      it 'returns the updated camera' do
        expect(last_response.json['cameras'].map{ |s| s['id'] }).
          to eq([camera.exid])
      end

      context 'when params are empty' do
        it 'returns a OK status and no changes' do
          patch("/cameras/#{camera.exid}", api_keys)
          expect(last_response.status).to eq(200)
        end
      end

      context 'when optional fields are blank' do
        it 'returns a OK status and nullifies values' do
          patch("/cameras/#{camera.exid}", params_blank.merge(api_keys))
          expect(last_response.status).to eq(200)
          cam = Camera.by_exid(camera.exid)
          expect(cam.vendor_model).to be_nil
          expect(cam.mac_address).to be_nil
          expect(cam.res_url('jpg')).to eq('')
          expect(cam.cam_username).to eq('')
          expect(cam.cam_password).to eq('')
          expect(cam.location).to be_nil
          expect(cam.config['external_host']).to eq('')
          expect(cam.config['internal_host']).to eq('')
          expect(cam.config['external_http_port']).to eq('')
          expect(cam.config['internal_http_port']).to eq('')
          expect(cam.config['external_rtsp_port']).to eq('')
          expect(cam.config['internal_rtsp_port']).to eq('')
        end
      end

    end

    context 'when snapshot url doesnt start with slash' do
      it 'returns a OK status' do
        patch("/cameras/#{camera.exid}", {jpg_url: 'image.jpg'}.merge(api_keys))
        expect(last_response.status).to eq(200)
        content = last_response.json
        expect(content).not_to be_nil
        expect(content.include?("cameras")).to eq(true)
        expect(content['cameras']).not_to be_nil
        expect(content['cameras'].length).not_to eq(0)
        expect(content['cameras'][0]).not_to be_nil
        expect(content['cameras'][0]['external']['http'].include?('jpg')).to eq(true)
        expect(content['cameras'][0]['external']['http']['jpg']).to end_with("/image.jpg")
      end
    end

    context 'when we want to remove port number with empty string from form' do
      it 'returns a OK status' do
        patch("/cameras/#{camera.exid}", {internal_http_port: ''}.merge(api_keys))
        expect(last_response.status).to eq(200)
        expect(last_response.json['cameras'][0]["internal_http_port"]).to be_nil
      end
    end

    context 'when name is too long' do
      it 'returns a 400 status' do
        patch("/cameras/#{camera.exid}", {name: 'Over 21 characters very long camera name'}.merge(api_keys))
        expect(last_response.status).to eq(400)
      end
    end

    context 'when no authentication is provided' do
      it 'returns an UNAUTHENTICATED status' do
        authorization_user.save
        expect(patch("/cameras/#{camera.exid}", params).status).to eq(401)
      end
    end

    context 'for a public camera with public shares' do
      let(:camera) { create(:camera, is_public: true, owner: authorization_user) }
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
          patch("/cameras/#{camera.exid}", params.merge(api_keys))

          expect(CameraShare.where(camera_id: camera.id,
                                   kind: CameraShare::PUBLIC).count).to eq(0)
          expect(CameraShare.where(camera_id: camera.id,
                                   kind: CameraShare::PRIVATE).count).to eq(1)
        end
      end
    end

  end

  describe 'DELETE /cameras' do

    let(:camera) { create(:camera, is_public: false, owner: authorization_user) }

    context 'when params are empty' do
      it 'returns a OK status' do
        skip
        delete("/cameras/#{camera.exid}", api_keys)
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

  describe 'GET /cameras' do
    let(:public_camera) { create(:camera) }
    let(:private_camera) { create(:camera, is_public: false) }
    let(:other_camera) { create(:camera, is_public: false) }
    let(:credentials) {{api_id: private_camera.owner.api_id,
                        api_key: private_camera.owner.api_key}}
    let(:parameters) {{ids: "#{public_camera.exid},#{private_camera.exid},#{other_camera.exid}"}}

    it 'returns only cameras that the user has permissions on when authentication is provided' do
      get("/cameras", parameters.merge(credentials))
      expect(last_response.status).to eq(200)
      data = last_response.json
      expect(data.include?("cameras")).to eq(true)
      expect(data["cameras"].size).to eq(2)
      data["cameras"].each do |camera|
        expect([public_camera.exid, private_camera.exid].include?(camera["id"])).to eq(true)
      end
    end
  end

  describe 'PUT /cameras/:id' do
    let(:camera) { create(:camera, is_public: false) }
    let(:owner) { camera.owner }
    let(:new_owner) { create(:user) }

    let(:credentials) {{api_id: owner.api_id, api_key: owner.api_key}}

    it 'returns success and the camera details when given valid parameters' do
      put "/cameras/#{camera.exid}", {user_id: new_owner.username}.merge(credentials)
      expect(last_response.status).to eq(200)
      expect(last_response.body.blank?).to eq(false)
      data = last_response.json
      expect(data).not_to be_nil
      expect(data.class).to eq(Hash)
      expect(data.include?("cameras")).to eq(true)
      expect(data["cameras"]).not_to be_nil
      expect(data["cameras"].class).to eq(Array)
      expect(data["cameras"].size).to eq(1)
      data = data["cameras"].first
      expect(data["id"]).to eq(camera.exid)
      expect(data["owner"]).to eq(new_owner.username)
    end

    it 'returns an unauthorized error if the caller is not the camera owner' do
      parameters = {api_id: new_owner.api_id, api_key: new_owner.api_key, user_id: new_owner.username}
      put "/cameras/#{camera.exid}", parameters
      expect(last_response.status).to eq(403)
      expect(last_response.body.blank?).to eq(false)
      data = last_response.json
      expect(data.class).to eq(Hash)
      expect(data.include?("message")).to eq(true)
      expect(data["message"]).to eq("Unauthorized")
    end

    it 'returns a not found error for a camera that does not exist' do
      put "/cameras/does_not_exist", {user_id: new_owner.username}.merge(credentials)
      expect(last_response.status).to eq(404)
      expect(last_response.body.blank?).to eq(false)
      data = last_response.json
      expect(data).not_to be_nil
      expect(data.class).to eq(Hash)
      expect(data.include?("message")).to eq(true)
      expect(data["message"]).to eq("The 'does_not_exist' camera does not exist.")
    end

    it 'returns a not found error when the new owner does not exist' do
      put "/cameras/#{camera.exid}", {user_id: 'unknown_user'}.merge(credentials)
      expect(last_response.status).to eq(404)
      expect(last_response.body.blank?).to eq(false)
      data = last_response.json
      expect(data).not_to be_nil
      expect(data.class).to eq(Hash)
      expect(data.include?("message")).to eq(true)
      expect(data["message"]).to eq("Specified user does not exist.")
    end

    it 'returns an unauthenticated error when no authentication details are provided' do
      put "/cameras/#{camera.exid}", {user_id: new_owner.username}
      expect(last_response.status).to eq(401)
      expect(last_response.body.blank?).to eq(false)
      data = last_response.json
      expect(data).not_to be_nil
      expect(data.class).to eq(Hash)
      expect(data.include?("message")).to eq(true)
      expect(data["message"]).to eq("Unauthenticated")
    end
  end
end
