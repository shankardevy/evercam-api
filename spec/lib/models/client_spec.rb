require 'data_helper'

describe Client do

  describe 'before_create' do

    it 'assigns a random #exid string' do
      client = create(:client)
      expect(client.exid).to_not be_nil
    end

    it 'assigns a random #secret string' do
      client = create(:client)
      expect(client.secret).to_not be_nil
    end

  end

end

