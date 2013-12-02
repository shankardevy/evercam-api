require 'data_helper'

describe DeviceVendor do

  subject { create(:device_vendor) }

  describe '#prefixes' do

    it 'auto upcases all prefixes' do
      subject.prefixes = ['aa:09:cc']
      expect(subject.prefixes).to eq(['AA:09:CC'])
    end

    it 'auto removes duplicate entries' do
      subject.prefixes = ['AA:BB:CC', 'AA:BB:CC']
      expect(subject.prefixes).to eq(['AA:BB:CC'])
    end

    it 'can be set to nil' do
      subject.prefixes = nil
      expect(subject.prefixes).to be_nil
    end

  end

  describe '::by_prefix' do

    it 'finds vendors using any string casing' do
      vendor0 = create(:device_vendor, prefixes: ['0A:0B:0C'])
      vendor1 = DeviceVendor.by_prefix('0a:0b:0C')
      expect(vendor1).to eq(vendor0)
    end

  end

end

