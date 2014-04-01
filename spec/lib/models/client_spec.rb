require 'data_helper'

describe Client do

  describe 'after_initialize' do

    it 'generates a 20 char random #api_id' do
      client = build(:client)
      expect(client.api_id.length).to be(20)
    end

    it 'generates a 32 char random #api_key' do
      client = build(:client)
      expect(client.api_key.length).to be(32)
    end

  end

  describe '#allow_callback_uri?' do
    context 'when the uri exactly matches an entry' do
      it 'returns true' do
        client = build(:client, callback_uris: ['http://evr.cm/oauth'])
        expect(client.allow_callback_uri?('http://evr.cm/oauth')).
          to eq(true)
      end
    end
    context 'when the uri starts with a matching entry' do
      it 'returns true' do
        client = build(:client, callback_uris: ['http://evr.cm/oauth'])
        expect(client.allow_callback_uri?('http://evr.cm/oauth/callback')).
          to eq(true)
      end
    end
    context 'when there are no matching entries' do
      it 'returns false' do
        client = build(:client, callback_uris: ['http://evr.cm/oauth'])
        expect(client.allow_callback_uri?('http://xxxx')).
          to eq(false)
      end
    end
  end

  describe '#settings property' do
  	it 'returns an empty hash when not explicitly set' do
      client = build(:client)
      expect(client.settings).to eq({})
    end

    it 'can be assigned from a Hash' do
      client = Client.create(exid: "client#{Time.now}")
      client.settings = {one: 'One', two: 2, three: 31.4}
      client.save
      client = Client[client.id]
      expect(client.settings).to eq({"one" => 'One', "two" => 2, "three" => 31.4})
    end
  end
end

