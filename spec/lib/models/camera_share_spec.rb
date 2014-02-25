require 'data_helper'

describe CameraShare do
	let(:user) {create(:user)}
	let(:owner) {create(:user)}
	let(:public_camera) {create(:camera, owner: owner, is_public: true)}
	let(:private_camera) {create(:camera, owner: owner, is_public: false)}

	describe '#new' do
		context 'when provided with all valid and required data' do
			it 'creates a valid instance' do
				share = CameraShare.new(user: user,
					                     camera: public_camera,
					                     kind: CameraShare::PUBLIC)
				expect(share.valid?).to eq(true)
			end
		end

		context 'when a user is not specified' do
			it 'creates an invalid instance' do
				share = CameraShare.new(camera: public_camera,
					                     kind: CameraShare::PUBLIC)
				expect(share.valid?).to eq(false)
			end
		end

		context 'when a camera is not specified' do
			it 'create an invalid instance' do
				share = CameraShare.new(user: user,
					                     kind: CameraShare::PUBLIC)
				expect(share.valid?).to eq(false)
			end
		end

		context 'when a share kind is not specified' do
			it 'create an invalid instance' do
				share = CameraShare.new(user: user,
					                     camera: public_camera)
				expect(share.valid?).to eq(false)
			end
		end

		context 'when an invalid share kind is specified' do
			it 'create an invalid instance' do
				share = CameraShare.new(user: user,
					                     camera: public_camera,
					                     kind: 'blah')
				expect(share.valid?).to eq(false)
			end
		end
	end

	describe 'instance method:' do
		let(:share) {create(:public_camera_share, camera: public_camera, user: user, sharer: owner)}

      describe '#camera' do
			it 'returns the correct camera' do
				expect(share.camera).to eq(public_camera)
			end
		end

      describe '#user' do
			it 'returns the correct user' do
				expect(share.user).to eq(user)
			end
		end

      describe '#sharer' do
			it 'returns the correct sharer' do
				expect(share.sharer).to eq(owner)
			end
		end
	end
end