require 'data_helper'

describe AccessScope do

  subject { AccessScope }

  let(:camera) { create(:camera) }

  let(:user) { create(:user) }

  describe '#resource' do

    context 'when the type is unknown' do
      it 'returns nil' do
        scope = subject.new("xxxx:view:#{camera.exid}")
        expect(scope.resource).to be_nil
      end
    end

    context 'when it is a camera' do
      it 'returns the instance of the camera' do
        scope = subject.new("camera:view:#{camera.exid}")
        expect(scope.resource).to eq(camera)
      end
    end

    context 'when it is a user' do
      it 'returns the instance of the user' do
        scope = subject.new("user:view:#{user.username}")
        expect(scope.resource).to eq(user)
      end
    end

  end

  describe '#valid?' do

    context 'when the type is unknown' do
      it 'returns false' do
        scope = subject.new("xxxx:view:yyyy")
        expect(scope.valid?).to eq(false)
      end
    end

    context 'when the resource does not exist' do
      it 'returns false' do
        scope = subject.new("camera:view:yyyy")
        expect(scope.valid?).to eq(false)
      end
    end

    context 'when the resource exists' do
      it 'returns true' do
        scope = subject.new("camera:view:#{camera.exid}")
        expect(scope.valid?).to eq(true)
      end
    end

  end

end

