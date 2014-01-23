require 'data_helper'

describe CameraEndpoint do

  describe '#to_s' do
    it 'returns a uri string representation' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '127.0.0.1', port: '80')
      expect(endpoint0.to_s).to eq('http://127.0.0.1:80')
    end
  end

  describe '#local?' do

    it 'returns true for 127.0.0.0/8 addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '127.0.0.1', port: '80')
      expect(endpoint0).to be_local
    end

    it 'returns false for all named addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: 'www.evercam.io', port: '80')
      expect(endpoint0).to_not be_local
    end

  end

  describe '#private?' do

    it 'returns true for 192.168.0.0/16 addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '192.168.1.1', port: '80')
      expect(endpoint0).to be_private
    end

    it 'returns true for 172.16.0.0/12 addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '172.20.1.1', port: '80')
      expect(endpoint0).to be_private
    end

    it 'returns true for 10.0.0.0/8 addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '10.10.1.1', port: '80')
      expect(endpoint0).to be_private
    end

    it 'returns false for all other ip addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '11.1.1.1', port: '80')
      expect(endpoint0).to_not be_private
    end

    it 'returns false for all named addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: 'www.evercam.io', port: '80')
      expect(endpoint0).to_not be_private
    end

  end

  describe '#public?' do

    it 'returns false for local addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '127.0.0.1', port: '80')
      expect(endpoint0).to_not be_public
    end

    it 'returns false for private addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '192.168.1.1', port: '80')
      expect(endpoint0).to_not be_public
    end

    it 'returns true for all other addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '11.1.1.1', port: '80')
      expect(endpoint0).to be_public
    end

    it 'returns true for all named addresses' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: 'www.evercam.io', port: '80')
      expect(endpoint0).to be_public
    end

  end

end

