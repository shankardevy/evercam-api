require 'data_helper'

describe Camera do

  let(:camera) { create(:camera) }

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
          right = create(:access_right, name: "camera:view:#{camera.exid}")
          expect(camera.allow?(:view, right.token)).to eq(true)
        end

        it 'is true when the auth includes an all cameras scope' do
          right = create(:access_right, name: "cameras:view:#{camera.owner.username}")
          expect(camera.allow?(:view, right.token)).to eq(true)
        end

        it 'is false when the auth has no privisioning scope' do
          right = create(:access_right, name: "camera:view:xxxx")
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

end

