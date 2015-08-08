require 'rack_helper'
require_app 'api/v1'

describe 'API routes/cameras' do

  let(:app) { Evercam::APIv1 }

  describe 'GET /public/cameras' do
    let!(:public_camera_1) {
      create(:camera, exid: 'exid_A_1', preview: 'aaa')
    }

    let!(:public_camera_2) {
      create(:camera, exid: 'exid_A_2', discoverable: false)
    }

    let!(:public_camera_3) {
      create(:camera, exid: 'exid_B_3')
    }

    let!(:public_camera_4) {
      create(:camera, exid: 'exid_B_4', discoverable: false)
    }

    let!(:public_camera_5) {
      create(:camera, exid: 'exid_A_5', location: '90.0 0.0')
    }

    let!(:private_camera_1) {
      create(:camera, exid: 'exid_P_1', is_public: false, discoverable: false)
    }

    let!(:private_camera_2) {
      create(:camera, exid: 'exid_P_2', is_public: false, discoverable: true)
    }

    context "where no parameters are specified" do
      it "returns success" do
        get('/public/cameras')
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(3)
      end
    end

    context "where thumbnails is true" do
      it "returns success" do
        get('/public/cameras', {thumbnail: true})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(3)
        cameras.each do |camera|
          expect(camera.include?('thumbnail')).to eq(true)
        end
      end
    end

    context "where a limit is specified" do
      it "returns success and the correct number of camera entries" do
        get('/public/cameras', {limit: 2})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(2)
      end

      it "accepts non-sensible limit values but ignores them" do
        get('/public/cameras', {limit: 0})
        expect(last_response.status).to eq(200)
      end
    end

    context "where an offset is specified" do
      it "returns success and the correct number of camera entries" do
        get('/public/cameras', {offset: 2})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(1)
      end

      it "accepts non-sensible offset values but ignores them" do
        get('/public/cameras', {offset: -1})
        expect(last_response.status).to eq(200)
      end
    end

    context "when is_near_to is specified" do

      context "as an address string" do

        before(:each) do
          WebMock.allow_net_connect!
        end

        after(:each) do
          WebMock.disable_net_connect!(:allow_localhost => true)
        end

        it "returns success and the correct camera entries" do
          skip
          get("/public/cameras", { is_near_to: 'The North Pole' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          cameras.each do |camera|
            expect(["exid_A_5"].include?(camera["id"])).to eq(true)
          end
        end

        it "excludes cameras outside the default distance of 1km" do
          get("/public/cameras", { is_near_to: 'The South Pole' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(0)
        end

        it "surfaces an error when address cannot be geocoded" do
          get("/public/cameras", { is_near_to: 'No Such Address' })
          expect(last_response.status).to eq(400)
          expect(last_response.json['message']).
            to eq('Unable to geocode "No Such Address"')
        end

      end

      context "as a lng lat point" do
        it "returns success and the correct camera entries" do
          get("/public/cameras", { is_near_to: '90, 0' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          cameras.each do |camera|
            expect(["exid_A_5"].include?(camera["id"])).to eq(true)
          end
        end
      end

      context "and within_distance is specified" do
        it "returns success and the correct camera entries" do
          get("/public/cameras", { is_near_to: '89.9, 0', within_distance: 99999 })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          cameras.each do |camera|
            expect(["exid_A_5"].include?(camera["id"])).to eq(true)
          end
        end
      end

    end

    context "where id_starts_with is specified" do
      it "returns success and the correct camera entries" do
        get('/public/cameras', {id_starts_with: 'exid_A'})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(2)
        cameras.each do |camera|
          expect(["exid_A_1", "exid_A_5"].include?(camera["id"])).to eq(true)
        end
      end
    end

    context "where id_ends_with is specified" do
      it "returns success and the correct camera entries" do
        get('/public/cameras', {id_ends_with: '5'})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(1)
        expect(cameras[0]["id"]).to eq("exid_A_5")
      end
    end

    context "where id_includes is specified" do
      it "returns success and the correct camera entries" do
        get('/public/cameras', {id_includes: '_A_'})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(2)
        cameras.each do |camera|
          expect(["exid_A_1", "exid_A_5"].include?(camera["id"])).to eq(true)
        end
      end
    end

    context "where case insensitive is specified" do
      it "returns success and the correct camera entries" do
        get('/public/cameras', {id_includes: 'EXID', case_sensitive: false})
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(3)
        cameras.each do |camera|
          expect(["exid_A_1", "exid_B_3", "exid_A_5"].include?(camera["id"])).to eq(true)
        end
      end
    end
  end

  describe 'GET /public/cameras/nearest' do
    let!(:public_camera_1) {
      create(:camera, exid: 'exid_A_1', preview: 'aaa')
    }

    let!(:public_camera_2) {
      create(:camera, exid: 'exid_A_2', discoverable: false)
    }

    let!(:public_camera_3) {
      create(:camera, exid: 'exid_B_3')
    }

    let!(:public_camera_4) {
      create(:camera, exid: 'exid_B_4', discoverable: false)
    }

    let!(:public_camera_5) {
      create(:camera, exid: 'exid_A_5', location: '0.0 90.0')
    }

    context "where no parameters are specified" do
      it "returns success" do
        get('/public/cameras/nearest')
        expect(last_response.status).to eq(200)
        data = last_response.json
        expect(data.include?("cameras")).to eq(true)
        expect(data.include?("message")).to eq(true)
        cameras = data["cameras"]
        expect(cameras.size).to eq(1)
        camera = cameras.first
        expect(camera.include?('thumbnail')).to eq(true)
        expect(data["message"]).
          to eq("Successfully Geocoded IP Address 127.0.0.1 as LAT: 0.0 LNG: 0.0")
      end
    end

    context "when near_to is specified" do

      context "as an address string" do

        before(:each) do
          WebMock.allow_net_connect!
        end

        after(:each) do
          WebMock.disable_net_connect!(:allow_localhost => true)
        end

        it "returns success and the correct location message" do
          get("/public/cameras/nearest", { near_to: 'Dublin' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          expect(data.include?("message")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          camera = cameras.first
          expect(camera.include?('thumbnail')).to eq(true)
          expect(data["message"]).
            to eq("Successfully Geocoded Dublin as LAT: 53.3498053 LNG: -6.2603097")
        end

        it "returns success and the correct camera entries" do
          get("/public/cameras/nearest", { near_to: 'The North Pole' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          cameras.each do |camera|
            expect(["exid_A_5"].include?(camera["id"])).to eq(true)
          end
        end

        it "surfaces an error when address cannot be geocoded" do
          get("/public/cameras/nearest", { near_to: 'No Such Address' })
          expect(last_response.status).to eq(400)
          expect(last_response.json['message']).
            to eq('Unable to geocode "No Such Address"')
        end
      end

      context "as a lng lat point" do
        it "returns success and the correct camera entries" do
          get("/public/cameras/nearest", { near_to: '0, 90' })
          expect(last_response.status).to eq(200)
          data = last_response.json
          expect(data.include?("cameras")).to eq(true)
          cameras = data["cameras"]
          expect(cameras.size).to eq(1)
          cameras.each do |camera|
            expect(["exid_A_5"].include?(camera["id"])).to eq(true)
          end
        end
      end
    end
  end
end
