require 'data_helper'

describe AccessRight do

  subject { AccessRight }

  describe '::split' do

    context 'resource specific right' do

      let(:right) { subject.split('a:b:c') }

      it 'extracts the group' do
        expect(right.group).to eq('a')
      end

      it 'extracts the right' do
        expect(right.right).to eq('b')
      end

      it 'extracts the scope' do
        expect(right.scope).to eq('c')
      end

    end

    context 'resource generic right' do

      let(:right) { subject.split('a:b') }

      it 'extracts the group' do
        expect(right.group).to eq('a')
      end

      it 'extracts the right' do
        expect(right.right).to eq('b')
      end

      it 'extracts nil scope' do
        expect(right.scope).to be_nil
      end

    end

  end

  describe '#resource' do

    context 'when the right is generic' do
      it 'returns nil' do
        right = subject.split('cameras:view:someone')
        expect(right.resource).to be_nil
      end
    end

    context 'when the right is specific' do
      it 'returns the resource instance' do
        camera = create(:camera)
        right = subject.split("camera:view:#{camera.exid}")
        expect(right.resource).to eq(camera)
      end
    end

  end

  describe '#generic?' do

    it 'returns false for camera' do
      expect(subject.new(group: 'camera').generic?).to eq(false)
    end

    it 'returns true for cameras' do
      expect(subject.new(group: 'cameras').generic?).to eq(true)
    end

  end

  describe '#valid?' do

    context 'when the right is generic' do
      it 'returns true' do
        expect(subject.split('cameras:view:someone')).to be_valid
      end
    end

    context 'when the right is specific' do

      context 'when the resource exists' do
        it 'returns true' do
          camera = create(:camera)
          expect(subject.split("camera:view:#{camera.exid}")).to be_valid
        end
      end

      context 'when the resource does not exist' do
        it 'returns false' do
          expect(subject.split('camera:view:xxxx')).to_not be_valid
        end
      end

    end

  end

  describe '#to_s' do
    it 'returns a basic string representation' do
      right = subject.split('abcd:view:xxxx')
      expect(right.to_s).to eq('abcd:view:xxxx')
    end
  end

end

