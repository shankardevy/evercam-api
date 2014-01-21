require 'data_helper'

describe AccessScope do

  subject { AccessScope }

  it 'is not valid when there are not three component parts' do
    scope = subject.new('bad')
    expect(scope).to_not be_valid
  end

  it 'is not valid when the type is unknown' do
    scope = subject.new('xxxx:view:abcd')
    expect(scope).to_not be_valid
  end

  it 'returns the type as a symbol' do
    scope = subject.new('camera:view:abcd')
    expect(scope.type).to eq(:camera)
  end

  it 'returns the right as a symbol' do
    scope = subject.new('camera:view:abcd')
    expect(scope.right).to eq(:view)
  end

  it 'returns the id as a string' do
    scope = subject.new('camera:view:abcd')
    expect(scope.id).to eq('abcd')
  end

  describe '^camera:' do

    let(:camera0) { create(:camera) }

    it 'is valid if the camera exists' do
      scope = subject.new("camera:view:#{camera0.exid}")
      expect(scope).to be_valid
    end

    it 'returns the camera resource' do
      scope = subject.new("camera:view:#{camera0.exid}")
      expect(scope.resource).to eq(camera0)
    end

    it 'is not valid if the resource does not exist' do
      scope = subject.new('camera:view:xxxx')
      expect(scope).to_not be_valid
    end

  end

  describe '^cameras:' do

    let(:user0) { create(:user) }

    it 'is valid if the user exists' do
      scope = subject.new("cameras:view:#{user0.username}")
      expect(scope).to be_valid
    end

    it 'returns the user resource' do
      scope = subject.new("cameras:view:#{user0.username}")
      expect(scope.resource).to eq(user0)
    end

    it 'is not valid if the resource does not exist' do
      scope = subject.new('cameras:view:xxxx')
      expect(scope).to_not be_valid
    end

  end

  describe '#to_s' do
    it 'returns a basic string representation' do
      scope = subject.new('abcd:view:xxxx')
      expect(scope.to_s).to eq('abcd:view:xxxx')
    end
  end

end

