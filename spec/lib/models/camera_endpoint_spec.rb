require 'data_helper'

describe CameraEndpoint do

  describe '#to_s' do
    it 'returns a uri string representation' do
      endpoint0 = CameraEndpoint.new(scheme: 'http', host: '127.0.0.1', port: '80')
      expect(endpoint0.to_s).to eq('http://127.0.0.1:80')
    end
  end

end

