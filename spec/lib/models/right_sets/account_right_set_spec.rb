require 'data_helper'

describe AccountRightSet do
	describe "accessors =>" do
		let(:user) { create(:user) }
		let(:client) { create(:client) }
		let(:rights) { AccountRightSet.new(user, client, AccessRight::CAMERAS) }

		describe "user" do
			it "returns the correct user" do
				expect(rights.user).to eq(user)
			end
		end

		describe "scope" do
			it "returns the correct scope setting" do
				expect(rights.scope).to eq(AccessRight::CAMERAS)
			end
		end
	end

	describe "rights checks" do
		let(:client) { create(:client) }
		let(:user) { create(:user) }
		let(:access_token) { create(:access_token, client: client) }
		let(:access_right) { create(:account_access_right, token: access_token, account: user) }
		let(:camera1) { create(:camera, owner: user, is_public: false) }
		let(:camera2) { create(:camera, owner: user, is_public: false) }

		describe "where the requester has an account level access right" do
			let(:access_right) { create(:account_access_right, token: access_token, account: user) }
      let(:rights) { AccountRightSet.new(user, client, AccessRight::CAMERAS) }

			before(:each) {access_right.save}

			it "returns true for the associated right" do
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
			end

			it "returns false for all other rights" do
				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
			end
		end

		describe "where the requester does not have an account level access right" do
   	  let(:rights) { AccountRightSet.new(user, client, AccessRight::CAMERAS) }

			it "returns false for all rights" do
				expect(rights.allow?(AccessRight::VIEW)).to eq(false)
				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
			end
		end

		describe "when accessed via individual resource right sets" do
			let(:rights) { AccessRightSet.for(camera1, client) }

			describe "and the requester has an account level access right" do
				let(:access_right) { create(:account_access_right, token: access_token, account: user) }

			  before(:each) {access_right.save}

				it "returns true for the associated right" do
					expect(rights.kind_of?(CameraRightSet)).to eq(true)
					expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				end

				it "returns false for all other rights" do
					expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
					expect(rights.allow?(AccessRight::LIST)).to eq(false)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				end
			end

			describe "and the requester does not haves an account level access right" do
				it "returns false for all rights" do
					expect(rights.kind_of?(CameraRightSet)).to eq(true)
					expect(rights.allow?(AccessRight::VIEW)).to eq(false)
					expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
					expect(rights.allow?(AccessRight::LIST)).to eq(false)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				end
			end
		end
	end
end