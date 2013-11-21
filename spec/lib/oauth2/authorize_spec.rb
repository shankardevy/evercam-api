require 'rack_helper'
require_lib 'oauth2'

module Evercam
  module OAuth2
    describe Authorize do

      subject { Authorize.new(params) }

      let(:client) do
        create(:client, callback_uris: ['http://127.0.0.1', 'http://evr.cm'])
      end

      let(:valid) do
        {
          response_type: 'token',
          client_id: client.exid,
          redirect_uri: 'http://evr.cm/oauth',
          scope: 'stream:view:xxxx'
        }
      end

      describe 'invalid requests' do

        context 'when :response_type is invalid' do

          context 'with :redirect_uri given' do

            let(:params) { valid.merge(response_type: 'xxxx') }

            its(:valid?) { should eq(false) }
            its(:redirect?) { should eq(true) }

            its(:uri) { should start_with('http://evr.cm/oauth#') }
            its(:uri) { should have_fragment({ error: :unsupported_response_type }) }

          end

          context 'with no :redirect_uri given' do

            let(:params) { valid.merge(response_type: 'xxxx', redirect_uri: nil) }

            its(:valid?) { should eq(false) }
            its(:redirect?) { should eq(true) }

            its(:uri) { should start_with('http://127.0.0.1#') }
            its(:uri) { should have_fragment({ error: :unsupported_response_type }) }

          end

          context 'when :client_id is invalid' do

            let(:params) { valid.merge(client_id: 'xxxx') }

            its(:valid?) { should eq(false) }
            its(:redirect?) { should eq(false) }
            its(:error) { should match(/client_id/i) }
            its(:uri) { should be_nil }

          end

          context 'when :redirect_uri is invalid' do

            let(:params) { valid.merge(redirect_uri: 'bad.uri') }

            its(:valid?) { should eq(false) }
            its(:redirect?) { should eq(false) }
            its(:error) { should match(/redirect_uri/i) }
            its(:uri) { should be_nil }

          end

        end

      end

    end
  end
end

