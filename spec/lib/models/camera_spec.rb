require 'data_helper'

describe Camera do

  let(:camera) { create(:camera) }

  describe '::by_exid!' do

    it 'returns the camera when it exists' do
      expect(Camera.by_exid!(camera.exid)).to eq(camera)
    end

    it 'raises a NotFoundError when it does not exist' do
      expect{ Camera.by_exid!('xxxx') }.
        to raise_error(Evercam::NotFoundError)
    end

  end

  describe '#allow?' do

    it 'is true for all rights when the auth is the owner' do
      expect(camera.allow?(:view, camera.owner.token)).to eq(true)
    end

    describe ':view right' do

      it 'is true when the camera is public' do
        camera.update(is_public: true)
        expect(camera.allow?(:view, nil)).to eq(true)
      end

      context 'when the camera is not public' do

        before(:each) do
          camera.update(is_public: false)
        end

        it 'is false when auth is nil' do
          expect(camera.allow?(:view, nil)).to eq(false)
        end

        it 'is true when auth includes specific camera scope' do
          right = create(:access_right, group: 'camera', right: 'view', scope: camera.exid)
          expect(camera.allow?(:view, right.token)).to eq(true)
        end

        it 'is true when the auth includes an all cameras scope' do
          right = create(:access_right, group: 'cameras', right: 'view', scope: camera.owner.username)
          expect(camera.allow?(:view, right.token)).to eq(true)
        end

        it 'is false when the auth has no provisioning scope' do
          right = create(:access_right, group: 'camera', right: 'view', scope: 'xxxx')
          expect(camera.allow?(:view, right.token)).to eq(false)
        end

      end

    end

  end

  describe '#timezone' do

    it 'defaults to UTC when no zone is specified' do
      expect(build(:camera, timezone: nil).timezone).
        to eq(Timezone::Zone.new zone: 'Etc/UTC')
    end

    it 'returns the correct zone instance when on is set' do
      expect(build(:camera, timezone: 'America/Chicago').timezone).
        to eq(Timezone::Zone.new zone: 'America/Chicago')
    end

  end

  describe '#config' do

    let(:firmware0) { create(:firmware, config: { 'a' => 'xxxx' }) }

    it 'returns camera config if firmware is nil' do
      d0 = create(:camera, firmware: nil, config: { 'a' => 'zzzz' })
      expect(d0.config).to eq({ 'a' => 'zzzz' })
    end

    it 'merges its config with that of its firmware' do
      d0 = create(:camera, firmware: firmware0, config: { 'b' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'xxxx', 'b' => 'yyyy'})
    end

    it 'gives precedence to values from the camera config' do
      d0 = create(:camera, firmware: firmware0, config: { 'a' => 'yyyy' })
      expect(d0.config).to eq({ 'a' => 'yyyy' })
    end

    it 'deep merges where both camera have the same keys' do
      firmware0.update(config: { 'a' => { 'b' => 'xxxx' } })
      d0 = create(:camera, firmware: firmware0, config: { 'a' => { 'c' => 'yyyy' } })
      expect(d0.config).to eq({ 'a' => { 'b' => 'xxxx', 'c' => 'yyyy' } })
    end

  end

  describe '#location' do

    let(:point) { '0101000020E610000000000000000024400000000000003440' }

    it 'returns nil when no location set' do
      expect(camera.location).to be_nil
    end

    it 'returns a GeoRuby Point when location is set' do
      camera.values[:location] = point
      expect(camera.location.x).to eq(10.0)
    end

    it 'sets the location to nil when nil passed' do
      camera.location = nil
      expect(camera.values[:location]).to be_nil
    end

    it 'sets the location value from a GeoRuby Point' do
      camera.location = GeoRuby::SimpleFeatures::Point.from_hex_ewkb(point)
      expect(camera.values[:location]).to eq(point)
    end

    it 'sets the location when passed a lng lat hash' do
      camera.location = { lng: 10, lat: 20 }
      expect(camera.values[:location]).to eq(point)
    end

  end

  describe '#firmware' do

    context 'when a firmware is specifically set' do
      it 'returns that specific firmware' do
        firmware = create(:firmware)
        camera.update(firmware: firmware)
        expect(camera.firmware).to eq(firmware)
      end
    end

    context 'when a firmware is not specifically set' do

      context 'when the mac address matches a supported vendor' do
        it 'returns the default firmware' do
          vendor = create(:vendor, known_macs: ['8C:E7:48'])
          firmware = create(:firmware, vendor: vendor, name: '*')

          camera.update(firmware: nil, mac_address: '8c:e7:48:bd:bd:f5')
          expect(camera.firmware).to eq(firmware)
        end
      end

      context 'when the mac address does not match a supported vendor' do
        it 'return nil' do
          camera.update(firmware: nil, mac_address: '8c:e7:48:bd:bd:f5')
          expect(camera.firmware).to be_nil
        end
      end

      context 'when the mac address is nil' do
        it 'return nil' do
          camera.update(firmware: nil, mac_address: nil)
          expect(camera.firmware).to be_nil
        end
      end

    end

  end

end

