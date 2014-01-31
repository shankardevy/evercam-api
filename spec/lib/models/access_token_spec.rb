require 'data_helper'

describe AccessToken do

  let(:token) { create(:access_token) }

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

  describe '#grantee' do

    let(:client) { create(:client) }

    context 'when it is a user permanent token' do
      it 'return the grantor (user)' do
        token = create(:access_token, grantee: nil)
        expect(token.grantee).to eq(token.grantor)
      end
    end

    context 'when it is a client temporary token' do
      it 'returns the grantee (client)' do
        token = create(:access_token, grantee: client)
        expect(token.grantee).to eq(client)
      end
    end

  end

  describe '#grant' do

    it 'adds an access right to the token' do
      token.grant('a:b:c')
      expect(token.includes?('a:b:c')).to eq(true)
    end

    it 'does not attempt to add the same scope twice' do
      expect{ 2.times { token.grant('a:b:c') } }.to_not raise_error
    end

  end

  describe '#revoke' do

    before(:each) { token.grant('a:b:c') }

    it 'removes an existing right from the token' do
      token.revoke('a:b:c')
      expect(token.includes?('a:b:c')).to eq(false)
    end

  end

  describe '#includes?' do

    it 'returns true when the access right has been granted' do
      token.grant('a:b:c')
      expect(token.includes?('a:b:c')).to eq(true)
    end

    it 'returns false when the access right has not been granted' do
      token.grant('a:b:c')
      expect(token.includes?('x:y:z')).to eq(false)
    end

  end

end

