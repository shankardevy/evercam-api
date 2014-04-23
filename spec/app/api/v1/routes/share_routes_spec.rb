require 'rack_helper'
require_app 'api/v1'

describe 'API routes/cameras' do

   let(:app) {
      Evercam::APIv1
   }
   let(:authorization_user) {
      create(:user)
   }
   let(:api_keys) {
      {api_id: authorization_user.api_id, api_key: authorization_user.api_key}
   }

   describe 'GET /shares/camera/:id' do
      let(:camera) { create(:camera, is_public: false, owner: authorization_user) }

      context "where shares don't exist" do
         let(:shares) {
            get("/shares/camera/#{camera.exid}", api_keys).json['shares']
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
            get("/shares/camera/#{camera.exid}", api_keys).json['shares']
         }

         it "returns a full list of shares for a camera" do
            expect(shares.size).to eq(2)
            expect(shares[0]).to have_keys('id', 'camera_id', 'user_id', 'email', 'kind', 'rights', 'sharer_id')
         end
      end
   end

   #----------------------------------------------------------------------------

   describe 'POST /shares/camera/:id' do
      let(:sharer) { create(:user) }
      let(:camera) { create(:camera, is_public: false, owner: authorization_user) }
      let(:public_camera) { create(:camera, is_public: true, discoverable: false) }
      let(:discoverable_camera) { create(:camera, is_public: true, discoverable: true) }
      let(:parameters) {{email: sharer.email, rights: "Snapshot,List"}}

      context "where an email address is not specified" do
         it "returns an error" do
            parameters.delete(:email)
            parameters.merge!(api_keys)
            response = post("/shares/camera/#{camera.exid}", parameters)
            expect(response.status).to eq(400)
         end
      end

      context "where rights are not specified" do
         it "returns an error" do
            parameters.delete(:rights)
            parameters.merge!(api_keys)
            response = post("/shares/camera/#{camera.exid}", parameters)
            expect(response.status).to eq(400)
         end
      end

      context "where the camera does not exist" do
         it "returns an error" do
            response = post("/shares/camera/blahblah", parameters.merge(api_keys))
            expect(response.status).to eq(404)
         end
      end

      context "where the user email does not exist" do
         it "returns an error" do
            parameters[:email] = "noone@nowhere.com"
            parameters.merge!(api_keys)
            response = post("/shares/camera/blah", parameters)
            expect(response.status).to eq(404)
         end
      end

      context "where the caller is not the owner of the camera and the camera is not public and discoverable" do
         it "returns an error" do
            not_owner = create(:user)
            parameters.merge!(api_id: not_owner.api_id, api_key: not_owner.api_key)
            response = post("/shares/camera/#{camera.exid}", parameters)
            expect(response.status).to eq(403)
         end
      end

      context "where the caller is not the owner of the camera and the camera is public but not discoverable" do
         it "returns an error" do
            not_owner = create(:user)
            parameters.merge!(api_id: not_owner.api_id, api_key: not_owner.api_key)
            response = post("/shares/camera/#{public_camera.exid}", parameters)
            expect(response.status).to eq(403)
         end
      end

      context "where the caller is not the owner of the camera and the camera is public and discoverable" do
         it "returns an error" do
            not_owner = create(:user)
            parameters.merge!(api_id: not_owner.api_id, api_key: not_owner.api_key)
            response = post("/shares/camera/#{discoverable_camera.exid}", parameters)
            expect(response.status).to eq(201)
         end
      end

      context "where the invalid rights are requested" do
         it "returns an error" do
            parameters[:rights] = "blah, ningy"
            parameters.merge!(api_keys)
            response = post("/shares/camera/#{camera.exid}", parameters)
            expect(response.status).to eq(400)
         end
      end

      context "when a proper request is sent" do
         it "returns success" do
            response = post("/shares/camera/#{camera.exid}", parameters.merge(api_keys))
            expect(response.status).to eq(201)
         end
      end    
   end

   #----------------------------------------------------------------------------

   describe 'DELETE /shares/camera/:id' do
      let(:sharer) { create(:user) }
      let(:camera) { create(:camera, is_public: false, owner: authorization_user) }

      context "where the share specified does not exist" do
         it "returns success" do
            response = delete("/shares/camera/#{camera.exid}", {share_id: -100}.merge(api_keys))
            expect(response.status).to eq(200)
         end
      end

      context "when deleting a share that exists" do
         let(:share) { create(:private_camera_share, camera: camera, user: authorization_user, sharer: sharer).save }

         context "where the camera specified does not exist" do
            it "returns a not found" do
               response = delete("/shares/camera/blahdeblah", {share_id: share.id}.merge(api_keys))
               expect(response.status).to eq(404)
            end
         end

         context "when the caller does not own the camera" do
            it "returns an error" do
               not_owner  = create(:user)
               parameters = {api_id: not_owner.api_id, api_key: not_owner.api_key, share_id: share.id}
               response = delete("/shares/camera/#{camera.exid}", parameters)
               expect(response.status).to eq(403)
            end
         end

         context "when proper request is sent" do
            it "returns success" do
               response = delete("/shares/camera/#{camera.exid}", {share_id: share.id}.merge(api_keys))
               expect(response.status).to eq(200)
            end
         end
      end
   end

   #----------------------------------------------------------------------------

   describe 'GET /shares/user/:id' do
      let!(:user1) {
         create(:user)
      }
      let!(:user2) {
         create(:user)
      }
      let!(:user3) {
         create(:user)
      }
      let!(:share1) {
         create(:public_camera_share, user: user1)
      }
      let!(:share2) {
         create(:private_camera_share, user: user1)
      }
      let!(:share3) {
         create(:public_camera_share, user: user2)
      }

      it 'returns an empty list for a user with no shares' do
         response = get("/shares/user/#{user3.username}", {api_id: user3.api_id, api_key: user3.api_key})
         expect(response.status).to eq(200)
         data = response.json
         expect(data.include?("shares")).to eq(true)
         expect(data["shares"]).not_to be_nil
         expect(data["shares"].size).to eq(0)
      end

      it 'returns a correct list of shares for a user with shares' do
         response = get("/shares/user/#{user1.username}", {api_id: user1.api_id, api_key: user1.api_key})
         expect(response.status).to eq(200)
         data = response.json
         expect(data.include?("shares")).to eq(true)
         expect(data["shares"]).not_to be_nil
         expect(data["shares"].size).to eq(2)
         data["shares"].each do |share|
            expect(share.include?("camera_id")).to eq(true)
            expect([share1.camera.exid, share2.camera.exid].include?(share["camera_id"])).to eq(true)
         end
      end

      it 'returns a not found error for a user that does not exist' do
         response = get("/shares/user/idontexist", api_keys)
         expect(response.status).to eq(404)
      end

      it 'returns an unauthenticated error when no credentials are supplied' do
         response = get("/shares/user/#{user1.username}", {})
         expect(response.status).to eq(401)
      end

      it 'returns an unauthenticated error when invalid credentials are supplied' do
         response = get("/shares/user/#{user1.username}", {api_id: '12345', api_key: '54321'})
         expect(response.status).to eq(401)
      end

      it 'returns an authorization error for a user with insufficient permissions' do
         response = get("/shares/user/#{user1.username}", api_keys)
         expect(response.status).to eq(403)
      end
   end
end