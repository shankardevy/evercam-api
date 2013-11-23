require 'spec_helper'
require_lib 'config'

module Evercam
  describe Config do

    subject { Evercam::Config }

    before(:each) do
      ENV['EVERCAM_ENV'] = nil
    end

    describe '::env' do

      it 'honors the EVERCAM_ENV variable' do
        ENV['EVERCAM_ENV'] = 'xxxx'
        expect(subject.env).to eq(:xxxx)
      end

      it 'defaults to development' do
        ENV['EVERCAM_ENV'] = nil
        expect(subject.env).to eq(:development)
      end

    end

    describe '::settings' do
      it 'returns all settings from the yaml file' do
        expect(subject.settings).to_not be(nil)
      end
    end

    describe '::[]' do
      it 'returns the settings for the current env' do
        development = subject.settings[:development]
        expect(subject[:database]).to eq(development[:database])
      end
    end

  end
end

