require 'data_helper'

describe Stream do

  let(:stream) { create(:stream) }

  describe '#has_right?' do

    context 'when the client is a user' do

      context 'when the user is the owner' do
        it 'returns true' do
          user = stream.owner
          expect(stream.has_right?('xxxx', user)).to be_true
        end
      end

      context 'when the user is not the owner' do
        it 'returns false' do
          user = create(:user)
          expect(stream.has_right?('xxxx', user)).to be_false
        end
      end

    end

  end

end

