require 'data_helper'

describe AccessRight do

  let(:right) { create(:camera_access_right) }

  describe "creating an access right" do
    let(:token) { create(:access_token) }
    let(:camera) { create(:camera) }

    describe "with all required values" do
      context "for a camera access right" do
        it "creates an object that will pass validation" do
          access_right = AccessRight.new(token:  token,
                                         camera: camera,
                                         status: AccessRight::ACTIVE,
                                         right:  AccessRight::VIEW)
          expect(access_right.valid?).to eq(true)
        end
      end

      context "for a snapshot access right" do
        let(:snapshot) { create(:snapshot) }

        it "creates an object that will pass validation" do
          access_right = AccessRight.new(token:  token,
                                         snapshot: snapshot,
                                         status: AccessRight::ACTIVE,
                                         right:  AccessRight::VIEW)
          expect(access_right.valid?).to eq(true)
        end
      end

      context "for an account access right" do
        let(:user) { create(:user) }

        it "creates an object that will pass validation" do
          access_right = AccessRight.new(token:  token,
                                         account: user,
                                         scope: AccessRight::CAMERAS,
                                         status: AccessRight::ACTIVE,
                                         right:  AccessRight::VIEW)
          expect(access_right.valid?).to eq(true)
        end
      end
    end

    describe "without a token" do
      it "creates an invalid object" do
        access_right = AccessRight.new(camera: camera,
                                       status: AccessRight::ACTIVE,
                                       right:  AccessRight::VIEW)
        expect(access_right.valid?).to eq(false)
      end
    end

    describe "without a camera" do
      it "creates an invalid object" do
        access_right = AccessRight.new(token:  token,
                                       status: AccessRight::ACTIVE,
                                       right:  AccessRight::VIEW)
        expect(access_right.valid?).to eq(false)
      end
    end

    describe "without a status setting" do
      it "creates an invalid object" do
        access_right = AccessRight.new(token:  token,
                                       camera: camera,
                                       right:  AccessRight::VIEW)
        expect(access_right.valid?).to eq(false)
      end
    end

    describe "with an invalid status setting" do
      it "creates an invalid object" do
        access_right = AccessRight.new(token:  token,
                                       camera: camera,
                                       status: 324,
                                       right:  AccessRight::VIEW)
        expect(access_right.valid?).to eq(false)
      end
    end

    describe "without a right" do
      it "creates a invalid object" do
        access_right = AccessRight.new(token:  token,
                                       camera: camera,
                                       status: AccessRight::ACTIVE)
        expect(access_right.valid?).to eq(false)
      end
    end

    describe "with an invalid right setting" do
      it "creates a invalid object" do
        access_right = AccessRight.new(token:  token,
                                       camera: camera,
                                       status: AccessRight::ACTIVE,
                                       right:  'blah')
        expect(access_right.valid?).to eq(false)
      end
    end
  end

  describe '#to_s' do
    it 'returns a basic string representation' do
      expect(right.to_s).to eq("#{right.camera_id}:#{right.token_id}:#{right.right}")
    end
  end

end

