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

  describe '#get_firmware_for' do

    let!(:firmware0) { create(:firmware, name: '*') }
    let!(:firmware1) { create(:firmware, vendor: firmware0.vendor, name: 'abcd') }

    subject { firmware0.vendor }

    it 'returns the default on no match' do
      firmware = subject.get_firmware_for('xxxx')
      expect(firmware).to eq(firmware0)
    end

    it 'returns an exact match' do
      firmware = subject.get_firmware_for('abcd')
      expect(firmware).to eq(firmware1)
    end

    it 'returns partial match' do
      firmware = subject.get_firmware_for('abcd-e')
      expect(firmware).to eq(firmware1)
    end

    it 'returns a case insensitive match' do
      firmware = subject.get_firmware_for('ABCD-E')
      expect(firmware).to eq(firmware1)
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

