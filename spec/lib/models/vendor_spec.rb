require 'data_helper'

describe Vendor do

  subject { Vendor }

  describe '#known_macs' do

    subject { create(:vendor) }

    it 'auto upcases all macs' do
      subject.known_macs = ['aa:09:cc']
      expect(subject.known_macs).to eq(['AA:09:CC'])
    end

    it 'auto removes duplicate entries' do
      subject.known_macs = ['AA:BB:CC', 'AA:BB:CC']
      expect(subject.known_macs).to eq(['AA:BB:CC'])
    end

    it 'can be set to nil' do
      subject.known_macs = nil
      expect(subject.known_macs).to be_nil
    end

  end

  describe '#get_model_for' do

    let!(:model0) { create(:vendor_model, name: '*') }
    let!(:model1) { create(:vendor_model, vendor: model0.vendor, name: 'abcd') }

    subject { model0.vendor }

    it 'returns the default on no match' do
      model = subject.get_model_for('xxxx')
      expect(model).to eq(model0)
    end

    it 'returns an exact match' do
      model = subject.get_model_for('abcd')
      expect(model).to eq(model1)
    end

    it 'returns partial match' do
      model = subject.get_model_for('abcd-e')
      expect(model).to eq(model1)
    end

    it 'returns a case insensitive match' do
      model = subject.get_model_for('ABCD-E')
      expect(model).to eq(model1)
    end

  end

  describe '::by_mac' do

    it 'finds vendors using any string casing' do
      vendor0 = create(:vendor, known_macs: ['0A:0B:0C'])
      vendor1 = subject.by_mac('0a:0b:0C').all
      expect(vendor1).to eq([vendor0])
    end

    it 'matches vendors only on the first three octets' do
      vendor0 = create(:vendor, known_macs: ['0A:0B:0C'])
      vendor1 = subject.by_mac('0a:0b:0C:00:00:00').all
      expect(vendor1).to eq([vendor0])
    end

  end

end

