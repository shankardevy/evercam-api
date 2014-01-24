require 'http_helper'
require_lib 'dns'

module Evercam
  module DNS
    describe ZoneManager, :vcr do

      subject do
        config = Evercam::Config[:amazon]
        ZoneManager.new('evr.cm', config)
      end

      let(:host) { 'unit-test-1234' }

      before(:each) do
        subject.delete(host)
      end

      describe '#create' do

        context 'when the record does not already exist' do
          it 'creates a new record' do
            subject.create(host, '127.0.0.1')
            address = subject.lookup(host)
            expect(address).to eq('127.0.0.1')
          end
        end

        context 'when the record already exist' do
          it 'does not change the record and returns nil' do
            subject.create(host, '127.0.0.1')

            outcome = subject.create(host, '127.0.0.2')
            expect(outcome).to be_nil

            address = subject.lookup(host)
            expect(address).to eq('127.0.0.1')
          end
        end

      end

      describe '#update' do

        context 'when the record does not already exist' do
          it 'creates a new record' do
            subject.update(host, '127.0.0.1')
            address = subject.lookup(host)
            expect(address).to eq('127.0.0.1')
          end
        end

        context 'when the record already exists' do
          it 'updates to the new address' do
            subject.update(host, '127.0.0.1')
            subject.update(host, '127.0.0.2')

            address = subject.lookup(host)
            expect(address).to eq('127.0.0.2')
          end
        end

      end

      describe '#lookup' do
        context 'when the record does not exist' do
          it 'returns nil' do
            address = subject.lookup(host)
            expect(address).to be_nil
          end
        end
      end

      describe '#delete' do

        context 'when the record does not exist' do
          it 'returns nil' do
            outcome = subject.delete(host)
            expect(outcome).to be_nil
          end
        end

        context 'when the record does exist' do
          it 'removes the record and returns its old address' do
            subject.update(host, '127.0.0.1')

            outcome = subject.delete(host)
            expect(outcome).to eq('127.0.0.1')

            address = subject.lookup(host)
            expect(address).to be_nil
          end
        end

      end

    end
  end
end

