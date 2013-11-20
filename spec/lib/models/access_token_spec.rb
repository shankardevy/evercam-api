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

end

