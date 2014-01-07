require 'data_helper'

describe Stream do

  let(:stream) { create(:stream) }

  describe '#has_right?' do

    context 'when the seeker is unknown' do
      it 'raises an AuthenticationError' do
        expect { stream.has_right?('xxxx', mock) }.
          to raise_error(Evercam::AuthorizationError)
      end
    end

    context 'when the seeker is a user' do

      context 'when the user is the owner' do
        it 'returns true' do
          user = stream.owner
          expect(stream.has_right?('xxxx', user)).
            to eq(true)
        end
      end

      context 'when the user is not the owner' do
        it 'returns false' do
          user = create(:user)
          expect(stream.has_right?('xxxx', user)).
            to eq(false)
        end
      end

    end

    context 'when the seeker is an access token' do

      context 'when the access token has the right' do
        it 'returns true' do
          atsr = create(:access_token_stream_right)
          token, stream = atsr.token, atsr.stream
          expect(stream.has_right?(atsr.name, token)).
            to eq(true)
        end
      end

      context 'when the access token does not have right' do
        it 'returns false' do
          atsr = create(:access_token_stream_right)
          token, stream = atsr.token, atsr.stream
          expect(stream.has_right?('xxxx', token)).
            to eq(false)
        end
      end

    end

  end

  describe '#config' do

    let(:firmware0) { create(:firmware, config: { 'a' => 'xxxx' }) }

    it 'returns stream config if firmware is nil' do
      d0 = create(:stream, firmware: nil, config: { 'a' => 'zzzz' })
      expect(d0.config).to eq({ 'a' => 'zzzz' })
    end

    it 'merges its config with that of its firmware' do
      d0 = create(:stream, firmware: firmware0, config: { 'b' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'xxxx', 'b' => 'yyyy'})
    end

    it 'gives precedence to values from the stream config' do
      d0 = create(:stream, firmware: firmware0, config: { 'a' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'yyyy' })
    end

    it 'deep merges where both stream have the same keys' do
      firmware0.update(config: { 'a' => { 'b' => 'xxxx' } })
      d0 = create(:stream, firmware: firmware0, config: { 'a' => { 'c' => 'yyyy' } })
      expect(d0.config).to eq({ 'a' => { 'b' => 'xxxx', 'c' => 'yyyy' } })
    end

  end

end

