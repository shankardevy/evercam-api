require 'data_helper'

describe Device do

  describe '#config' do

    let(:firmware0) { create(:firmware, config: { 'a' => 'xxxx' }) }

    it 'merges its config with that of its firmware' do
      d0 = create(:device, firmware: firmware0, config: { 'b' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'xxxx', 'b' => 'yyyy'})
    end

    it 'gives precedence to values from the device config' do
      d0 = create(:device, firmware: firmware0, config: { 'a' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'yyyy' })
    end

  end

end

