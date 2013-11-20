require 'data_helper'

describe Stream do

  let(:stream) { create(:stream) }

  describe '#has_right?' do

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

end

