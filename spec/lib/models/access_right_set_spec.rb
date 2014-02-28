require 'data_helper'

describe AccessRightSet do
	context "accessors =>" do
		let(:camera) { create(:camera) }
		let(:client) { create(:client) }
		let(:user)   { create(:user) }

		it "resource" do
			rights = AccessRightSet.new(camera, user)
			expect(rights.resource).to eq(camera)
		end

		it "requester" do
			rights = AccessRightSet.new(camera, user)
			expect(rights.requester).to eq(user)
		end

		it "type" do
			rights = AccessRightSet.new(camera, user)
			expect(rights.type).to eq(:user)

			rights = AccessRightSet.new(camera, client)
			expect(rights.type).to eq(:client)
		end
	end

	context "for user right sets" do
		context "where the resource is not public" do
			let(:camera) { create(:camera, is_public: false) }

			context "and the user is not the resource owner" do
				let(:user) { create(:user, id: -100) }

				it "returns false for all rights tests" do
					rights = AccessRightSet.new(camera, user)

					expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
					expect(rights.allow?(AccessRight::LIST)).to eq(false)
					expect(rights.allow?(AccessRight::VIEW)).to eq(false)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
				end
			end
		end

		context "where the resource is public" do
			let(:camera) { create(:camera) }

			context "and the user is not the resource owner" do
				let(:user) { create(:user, id: -100) }

				it "returns true only for the snapshot and list rights" do
					rights = AccessRightSet.new(camera, user)

					expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(true)
					expect(rights.allow?(AccessRight::LIST)).to eq(true)
					expect(rights.allow?(AccessRight::VIEW)).to eq(false)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
				end
			end
		end

		context "where the user is the resource owner" do
			let(:user)   { create(:user) }
			let(:camera) { create(:camera, is_public: false, owner_id: user.id) }

			it "returns true for all rights" do
				rights = AccessRightSet.new(camera, user)

				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(true)
				expect(rights.allow?(AccessRight::LIST)).to eq(true)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(true)
				expect(rights.allow?(AccessRight::DELETE)).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(true)
			end
		end
	end

	context "for client right sets" do
		context "where the resource is not public" do
			let(:camera) { create(:camera, is_public: false) }
			let(:client) { create(:client) }

			it "returns false for all rights tests" do
				rights = AccessRightSet.new(camera, client)

				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(false)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
			end
		end
	end

	describe "#grant" do
		let(:camera) { create(:camera, is_public: false) }

		context "for clients" do
			let(:client) { create(:client) }
			let(:access_token) { create(:access_token, client: client) }
			let(:rights) { AccessRightSet.new(camera, client) }

			before(:each) {access_token.save}

			it "doesn't grant rights that aren't explcitly specified" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
			end

			it "provides a requester with privilege to a specified right" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
			end

			it "can handle multiple rights in a single request" do
				rights.grant(AccessRight::EDIT, AccessRight::DELETE)
				expect(rights.allow?(AccessRight::EDIT)).to eq(true)
				expect(rights.allow?(AccessRight::DELETE)).to eq(true)
			end
		end

		context "for users" do
			let(:user) { create(:user, id: -200) }
			let(:access_token) { create(:access_token, user: user) }
			let(:rights) { AccessRightSet.new(camera, user) }

			before(:each) {access_token.save}

			it "doesn't grant rights that aren't explcitly specified" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
			end

			it "provides a requester with privilege to a specified right" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
			end

			it "can handle multiple rights in a single request" do
				rights.grant(AccessRight::EDIT, AccessRight::DELETE)
				expect(rights.allow?(AccessRight::EDIT)).to eq(true)
				expect(rights.allow?(AccessRight::DELETE)).to eq(true)
			end
		end
	end

	describe "#revoke" do
		let(:camera) { create(:camera, is_public: false) }

		context "for clients" do
			let(:client) { create(:client) }
			let(:access_token) { create(:access_token, client: client) }
			let(:rights) { AccessRightSet.new(camera, client) }

			before(:each) {
				access_token.save
				rights.grant(*AccessRight::BASE_RIGHTS)
			}

         it "removes a privilege from a requester" do
         	expect(rights.allow?(AccessRight::DELETE)).to eq(true)
         	rights.revoke(AccessRight::DELETE)
         	expect(rights.allow?(AccessRight::DELETE)).to eq(false)
         end

         it "can handle multiple rights in a single request" do
         	expect(rights.allow?(AccessRight::DELETE)).to eq(true)
         	expect(rights.allow?(AccessRight::VIEW)).to eq(true)
         	rights.revoke(AccessRight::DELETE, AccessRight::VIEW)
         	expect(rights.allow?(AccessRight::DELETE)).to eq(false)
         	expect(rights.allow?(AccessRight::VIEW)).to eq(false)
         end
		end


		context "for users" do
			let(:user) { create(:user, id: -300) }
			let(:access_token) { create(:access_token, user: user) }
			let(:rights) { AccessRightSet.new(camera, user) }

			before(:each) {
				access_token.save
				rights.grant(*AccessRight::BASE_RIGHTS)
			}

         it "removes a privilege from a requester" do
         	expect(rights.allow?(AccessRight::DELETE)).to eq(true)
         	rights.revoke(AccessRight::DELETE)
         	expect(rights.allow?(AccessRight::DELETE)).to eq(false)
         end

         it "can handle multiple rights in a single request" do
         	expect(rights.allow?(AccessRight::DELETE)).to eq(true)
         	expect(rights.allow?(AccessRight::VIEW)).to eq(true)
         	rights.revoke(AccessRight::DELETE, AccessRight::VIEW)
         	expect(rights.allow?(AccessRight::DELETE)).to eq(false)
         	expect(rights.allow?(AccessRight::VIEW)).to eq(false)
         end
		end
   end

   context "for clients with multiple tokens" do
   	let(:camera) { create(:camera, is_public: false) }
   	let(:client) { create(:client) }
   	let(:token1) { create(:access_token) }
   	let(:token1) {
   		token  = AccessToken.create(client: client)
   		rights = AccessRightSet.new(camera, client)
   		rights.grant(*AccessRight::BASE_RIGHTS)
   		token
   	}

   	before(:each) do
   		token1.save
   	end

   	it "picks up grants from earlier tokens" do
   		token2 = AccessToken.create(client: client)

   		rights = AccessRightSet.new(camera, client)
   		expect(rights.allow?(AccessRight::VIEW)).to eq(true)
   	end
   end
end