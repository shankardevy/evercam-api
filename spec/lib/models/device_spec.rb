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

    it 'deep merges where both config have the same keys' do
      firmware0.update(config: { 'a' => { 'b' => 'xxxx' } })
      d0 = create(:device, firmware: firmware0, config: { 'a' => { 'c' => 'yyyy' } })
      expect(d0.config).to eq({ 'a' => { 'b' => 'xxxx', 'c' => 'yyyy' } })
    end

    it 'returns the firmware config when device config is nil' do
      d0 = create(:device, firmware: firmware0, config: nil)
      expect(d0.config).to eq({ 'a' => 'xxxx' })
    end

  end

end

