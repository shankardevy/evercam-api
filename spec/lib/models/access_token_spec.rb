require 'data_helper'

describe AccessToken do

  describe 'after_initialize' do

    it 'generates a 32 char random #request' do
      token = build(:access_token)
      expect(token.request.length).to be(32)
    end

    it 'defaults expires_at to 3600 seconds from now' do
      token = build(:access_token)
      expect(token.expires_at).to_not be_nil
    end

    it 'defaults is_revoked to false' do
      token = build(:access_token)
      expect(token.is_revoked?).to eq(false)
    end

  end

  describe '#is_valid?' do

    context 'when has been revoked' do
      it 'returns false' do
        token = build(:access_token, is_revoked: true)
        expect(token.is_valid?).to eq(false)
      end
    end

    context 'when it has past its expiry' do
      it 'returns false' do
        token = build(:access_token, expires_at: Time.now - 1)
        expect(token.is_valid?).to eq(false)
      end
    end

    context 'when all token params are valid' do
      it 'returns true' do
        token = build(:access_token)
        expect(token.is_valid?).to eq(true)
      end
    end

  end

  describe '#expires_in' do

    context 'when the token is still valid' do
      it 'returns the number of seconds remaining' do
        token = build(:access_token)
        expect(token.expires_in).to be > 0
      end
    end

    context 'when the token has expired' do
      it 'returns zero' do
        token = build(:access_token, expires_at: Time.now - 1)
        expect(token.expires_in).to eq(0)
      end
    end

  end

  describe '#owner' do

    context 'when it is a user permanent token' do
      it 'return the grantor (user)' do
        token = create(:access_token, grantee: nil)
        expect(token.owner).to eq(token.grantor)
      end
    end

    context 'when it is a client temporary token' do
      it 'returns the grantee (client)' do
        token = create(:access_token)
        expect(token.owner).to eq(token.grantee)
      end
    end

  end

  describe '#allow?' do

    it 'returns true when the access right has been granted' do
      token = create(:access_right, name: 'xxxx').token
      expect(token.allow?('xxxx')).to eq(true)
    end

    it 'returns false when the access right has not been granted' do
      token = create(:access_right, name: 'xxxx').token
      expect(token.allow?('aaaa')).to eq(false)
    end

  end

end

