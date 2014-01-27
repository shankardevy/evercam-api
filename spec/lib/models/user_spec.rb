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
      token.update(grantee: create(:client))
      expect(user.token(true)).to_not eq(token)
    end

    it 'is not associated with any client' do
      expect(token.grantee).to be_nil
    end

    it 'is a valid token' do
      expect(token.is_valid?).to eq(true)
    end

  end

  describe '#grants' do

    let(:grant0) { create(:access_token, grantor: user) }

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

  describe '#scopes' do

    context 'when the database is null' do
      it 'returns an empty set' do
        user0 = User.new(scopes: nil)
        expect(user0.scopes).to be_empty
      end
    end

    it 'allows common operators like #append' do
      user0 = build(:user, scopes: nil)
      user0.scopes.append('test:scope')
      expect(user0.scopes).to eq(['test:scope'])
    end

    it 'persists scopes across saves' do
      user0 = build(:user, scopes: nil)

      user0.scopes.append('test:scope')
      user0.save

      expect(User[user0.pk].scopes).to eq(['test:scope'])
    end

  end

end

