require 'data_helper'

describe Client do

  describe 'after_initialize' do

    it 'generates a 20 char random #exid' do
      client = build(:client)
      expect(client.exid.length).to be(20)
    end

    it 'generates a 32 char random #secret' do
      client = build(:client)
      expect(client.secret.length).to be(32)
    end

  end

end

