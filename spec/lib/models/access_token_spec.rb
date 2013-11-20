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

  end

end

