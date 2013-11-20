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

end

