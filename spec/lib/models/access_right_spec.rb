require 'data_helper'

describe AccessRight do

  subject { AccessRight }

  describe '::split' do

    context 'resource specific right' do

      let(:right) { subject.split('a:b:c') }

      it 'extracts the group' do
        expect(right.group).to eq('a')
      end

      it 'extracts the right' do
        expect(right.right).to eq('b')
      end

      it 'extracts the scope' do
        expect(right.scope).to eq('c')
      end

    end

    context 'resource generic right' do

      let(:right) { subject.split('a:b') }

      it 'extracts the group' do
        expect(right.group).to eq('a')
      end

      it 'extracts the right' do
        expect(right.right).to eq('b')
      end

      it 'extracts nil scope' do
        expect(right.scope).to be_nil
      end

    end

  end

end

