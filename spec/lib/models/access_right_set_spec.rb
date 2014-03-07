require 'data_helper'

describe AccessRightSet do
	context "accessors =>" do
		let(:camera) { create(:camera) }
		let(:client) { create(:client) }
		let(:user)   { create(:user) }
		let(:access_token1) { create(:access_token, client: client, user: nil) }
		let(:access_token2) { create(:access_token, user: user, client: nil) }

		before(:each) do
			access_token1.save
			access_token2.save
		end

		it "resource" do
			rights = AccessRightSet.for(camera, user)
			expect(rights.resource).to eq(camera)
		end

		it "requester" do
			rights = AccessRightSet.for(camera, user)
			expect(rights.requester).to eq(user)
		end

		it "type" do
			rights = AccessRightSet.for(camera, user)
			expect(rights.type).to eq(:user)

			rights = AccessRightSet.for(camera, client)
			expect(rights.type).to eq(:client)
		end

		it "token" do
			rights = AccessRightSet.for(camera, client)
			expect(rights.token.id).to eq(access_token1.id)

			rights = AccessRightSet.for(camera, user)
			expect(rights.token.id).to eq(access_token2.id)
		end
	end
end