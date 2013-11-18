require 'spec_helper'
require_lib 'config'

module Evercam
  describe Config do

    subject { Evercam::Config }

    before(:each) do
      stub_const("ENV", {})
    end

    describe '::env' do

      it 'defaults to development' do
        expect(subject.env).to eq(:development)
      end

      it 'honors the EVERCAM_ENV variable' do
        ENV['EVERCAM_ENV'] = 'xxxx'
        expect(subject.env).to eq(:xxxx)
      end

    end

    describe '::settings' do

      it 'returns the settings from the yaml file' do
        expect(subject.settings).to_not be(nil)
      end

    end

    describe '::database' do

      it 'returns the connection settings from yaml' do
        expect(subject.database).to_not be_nil
      end

      it 'honors the DATABASE_URL variable' do
        ENV['DATABASE_URL'] = 'xxxx'
        expect(subject.database).to eq('xxxx')
      end

    end

    describe '::cookies' do

      it 'returns the cookie settings from yaml' do
        expect(subject.cookies).to_not be_nil
      end

    end

  end
end

