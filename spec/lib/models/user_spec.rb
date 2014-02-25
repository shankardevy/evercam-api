require 'data_helper'

describe User do

  let(:user) { create(:user) }

  describe '#by_login' do

    context 'when given a username' do
      it 'finds the user' do
        found = User.by_login(user.username)
        expect(found).to eq(user)
      end
    end

    context 'when given an email' do
      it 'finds the user' do
        found = User.by_login(user.email)
        expect(found).to eq(user)
      end
    end

  end

  describe '#token' do

    let(:token) { user.token }

    it 'is auto created for new users' do
      expect(token).to_not be_nil
    end

    it 'is auto created for existing users' do
      user.token.delete
      expect(user.token(true)).to_not be_nil
    end

    it 'does not replace existing tokens' do
      expect{ user.save }.to_not change{ user.token }
    end

    it 'is a permanent token' do
      expect(token.expires_at).to eq(Time.at(2**31))
    end

    it 'only returns the permanent token' do
      token.update(client: create(:client))
      expect(user.token(true)).to_not eq(token)
    end

    it 'is a valid token' do
      expect(token.is_valid?).to eq(true)
    end

  end

  describe '#grants' do

    let(:grant0) { create(:access_token, user: user) }

    it 'returns only granted tokens' do
      expect(user.grants(true)).to be_dataset([grant0])
    end

  end

  describe '#password' do

    context 'when setting a new value' do
      it 'stores it using bcrypt cost 10' do
        user0 = User.new(password: 'garrett')
        hash0 = BCrypt::Password.new(user0.values[:password])
        expect(hash0.cost).to eq(10)
      end
    end

    context 'when reading an existing value' do
      it 'returns a bcrypt password checking object' do
        hash0 = BCrypt::Password.create('garrett')
        user0 = User.load(password: hash0.to_s)
        expect(user0.password).to eq('garrett')
      end
    end

  end

  describe '#shares' do
    let(:owner) { create(:user) }
    let(:private_camera) { create(:camera, owner: owner, is_public: false) }
    let(:public_camera) { create(:camera, owner: owner, is_public: true) }
    let(:private_camera_share) { create(:private_camera_share, camera: private_camera, sharer: owner, user: user) }
    let(:public_camera_share) { create(:public_camera_share, camera: public_camera, sharer: owner, user: user) }

    before(:each) {private_camera_share.save; public_camera_share.save}

    it 'returns only granted camera shares' do
      shares = user.camera_shares
      expect(shares.length).to eq(2)
      shares.each do |share|
        [public_camera_share.id, private_camera_share.id].include?(share.id)
      end
    end
  end

end

