require 'data_helper'

describe SnapshotRightSet do
	context "accessors =>" do
		let(:snapshot) { create(:snapshot) }
		let(:client) { create(:client) }
		let(:user)   { create(:user) }

		it "returns a snapshot for a call to the #snapshot method" do
			rights = SnapshotRightSet.new(snapshot, user)
			expect(rights.snapshot).to eq(snapshot)
		end

      it "returns and approprite true or false for rights passed to the #valid_right? method" do
			rights = SnapshotRightSet.new(snapshot, user)
			expect(rights.valid_right?(AccessRight::SNAPSHOT)).to eq(false)
			expect(rights.valid_right?(AccessRight::LIST)).to eq(true)
			expect(rights.valid_right?(AccessRight::VIEW)).to eq(true)
			expect(rights.valid_right?(AccessRight::EDIT)).to eq(true)
			expect(rights.valid_right?(AccessRight::DELETE)).to eq(true)
			expect(rights.valid_right?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
			expect(rights.valid_right?("#{AccessRight::GRANT}~#{AccessRight::LIST}")).to eq(true)
			expect(rights.valid_right?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(true)
			expect(rights.valid_right?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(true)
			expect(rights.valid_right?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(true)
      end
	end

	context "for user right sets" do
		context "where the resource is not public" do
			let(:snapshot) { create(:snapshot, is_public: false) }

			context "and the user is not the resource owner" do
				let(:user) { create(:user, id: -100) }

				it "returns false for all rights tests" do
					rights = SnapshotRightSet.new(snapshot, user)

					expect(rights.allow?(AccessRight::LIST)).to eq(false)
					expect(rights.allow?(AccessRight::VIEW)).to eq(false)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
				end
			end
		end

		context "where the resource is public" do
			let(:snapshot) { create(:snapshot, is_public: true) }

			context "and the user is not the resource owner" do
				let(:user) { create(:user, id: -100) }

				it "returns true only for the snapshot and list rights" do
					rights = SnapshotRightSet.new(snapshot, user)

					expect(rights.allow?(AccessRight::LIST)).to eq(true)
					expect(rights.allow?(AccessRight::VIEW)).to eq(true)
					expect(rights.allow?(AccessRight::EDIT)).to eq(false)
					expect(rights.allow?(AccessRight::DELETE)).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
					expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
				end
			end
		end

		context "where the user is the resource owner" do
			let(:user)   { create(:user) }
			let(:camera) { create(:camera, owner: user) }
			let(:snapshot) { create(:snapshot, is_public: false, camera: camera) }

			it "returns true for all rights" do
				rights = SnapshotRightSet.new(snapshot, user)

				expect(rights.allow?(AccessRight::LIST)).to eq(true)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(true)
				expect(rights.allow?(AccessRight::DELETE)).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(true)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(true)
			end
		end
	end

	context "for client right sets" do
		context "where the resource is not public" do
			let(:snapshot) { create(:snapshot, is_public: false) }
			let(:client) { create(:client) }

			it "returns false for all rights tests" do
				rights = SnapshotRightSet.new(snapshot, client)

				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(false)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
				expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
			end
		end
	end

	describe "#can_grant?" do
		let(:user)   { create(:user) }

		context "where the user is the snapshot owner" do
			let(:camera) { create(:camera, owner: user) }
         let(:snapshot) { create(:snapshot, is_public: false, camera: camera) }

			it "returns true for all valid rights" do
				rights = SnapshotRightSet.new(snapshot, user)
				expect(rights.can_grant?(AccessRight::LIST)).to eq(true)
				expect(rights.can_grant?(AccessRight::VIEW)).to eq(true)
				expect(rights.can_grant?(AccessRight::EDIT)).to eq(true)
				expect(rights.can_grant?(AccessRight::DELETE)).to eq(true)
			end
		end

		context "where the user is not the owner of the snapshot and has no rights on it" do
         let(:snapshot) { create(:snapshot, is_public: false) }

			it "returns false for all valid rights" do
				rights = SnapshotRightSet.new(snapshot, user)
				expect(rights.can_grant?(AccessRight::LIST)).to eq(false)
				expect(rights.can_grant?(AccessRight::VIEW)).to eq(false)
				expect(rights.can_grant?(AccessRight::EDIT)).to eq(false)
				expect(rights.can_grant?(AccessRight::DELETE)).to eq(false)
			end
		end

		context "where the user is not the owner but has some grant rights on the snapshot" do
         let(:snapshot) { create(:snapshot, is_public: false) }
			let(:client) { create(:client) }
			let(:access_token) { create(:access_token, client: client) }
			let(:rights) { SnapshotRightSet.new(snapshot, client)}
         before(:each) do
         	rights.grant("#{AccessRight::GRANT}~#{AccessRight::EDIT}",
         		          "#{AccessRight::GRANT}~#{AccessRight::DELETE}")
         end

			it "returns true or false depending on the requesters permissions" do
				expect(rights.can_grant?(AccessRight::LIST)).to eq(false)
				expect(rights.can_grant?(AccessRight::VIEW)).to eq(false)
				expect(rights.can_grant?(AccessRight::EDIT)).to eq(true)
				expect(rights.can_grant?(AccessRight::DELETE)).to eq(true)
			end
		end
	end

	describe "#grant" do
		let(:snapshot) { create(:snapshot, is_public: false) }

		context "for clients" do
			let(:client) { create(:client) }
			let(:access_token) { create(:access_token, client: client) }
			let(:rights) { SnapshotRightSet.new(snapshot, client) }

			before(:each) {access_token.save}

			it "doesn't grant rights that aren't explcitly specified" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
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

			it "raises an exception for invalid rights" do
				expect {rights.grant(AccessRight::SNAPSHOT)}.to raise_error(RuntimeError)
				expect {rights.grant("blah")}.to raise_error(RuntimeError)
			end
		end

		context "for users" do
			let(:user) { create(:user, id: -200) }
			let(:access_token) { create(:access_token, user: user) }
			let(:rights) { SnapshotRightSet.new(snapshot, user) }

			before(:each) {access_token.save}

			it "doesn't grant rights that aren't explcitly specified" do
				rights.grant(AccessRight::VIEW)
				expect(rights.allow?(AccessRight::LIST)).to eq(false)
				expect(rights.allow?(AccessRight::VIEW)).to eq(true)
				expect(rights.allow?(AccessRight::EDIT)).to eq(false)
				expect(rights.allow?(AccessRight::DELETE)).to eq(false)
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

			it "raises an exception for invalid rights" do
				expect {rights.grant(AccessRight::SNAPSHOT)}.to raise_error(RuntimeError)
				expect {rights.grant("blah")}.to raise_error(RuntimeError)
			end
		end
	end

	describe "#revoke" do
		let(:snapshot) { create(:snapshot, is_public: false) }

		context "for clients" do
			let(:client) { create(:client) }
			let(:access_token) { create(:access_token, client: client) }
			let(:rights) { SnapshotRightSet.new(snapshot, client) }

			before(:each) {
				access_token.save
				rights.grant(*(AccessRight::BASE_RIGHTS - [AccessRight::SNAPSHOT]))
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
			let(:rights) { SnapshotRightSet.new(snapshot, user) }

			before(:each) {
				access_token.save
				rights.grant(*(AccessRight::BASE_RIGHTS - [AccessRight::SNAPSHOT]))
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
   	let(:snapshot) { create(:snapshot, is_public: false) }
   	let(:client) { create(:client) }
   	let(:token1) { create(:access_token) }
   	let(:token1) {
   		token  = AccessToken.create(client: client)
   		rights = SnapshotRightSet.new(snapshot, client)
   		rights.grant(*(AccessRight::BASE_RIGHTS - [AccessRight::SNAPSHOT]))
   		token
   	}

   	before(:each) do
   		token1.save
   	end

   	it "picks up grants from earlier tokens" do
   		token2 = AccessToken.create(client: client)

   		rights = SnapshotRightSet.new(snapshot, client)
   		expect(rights.allow?(AccessRight::VIEW)).to eq(true)
   	end
   end
end