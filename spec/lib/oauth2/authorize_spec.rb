require 'rack_helper'
require_lib 'oauth2'

module Evercam
  module OAuth2
    describe Authorize do

      subject { Authorize.new(user, params) }

      let(:atsr) { create(:access_token_stream_right) }

      let(:user) { atsr.token.grantor }

      let(:client) do
        atsr.token.grantee.tap do |c|
          c.update(callback_uris: ['http://a', 'http://b'])
        end
      end

      let(:valid) do
        {
          response_type: 'token',
          client_id: client.exid,
          redirect_uri: client.default_callback_uri,
          scope: "stream:view:#{atsr.stream.name}"
        }
      end

      context 'when the request is invalid' do

        it 'returns false from #valid? for any form on error' do
          params = valid.merge(response_type: 'xxxx')
          request = Authorize.new(user, params)
          expect(request.valid?).to eq(false)
        end

        context 'and a valid :redirect_uri is given' do
          let(:params) { valid.merge(scope: nil, redirect_uri: 'http://b') }
          its(:redirect?) { should eq(true) }
          its(:redirect_to) { should start_with('http://b') }
        end

        context 'and no :redirect_uri is given' do
          let(:params) { valid.merge(scope: nil, redirect_uri: nil) }
          its(:redirect?) { should eq(true) }
          its(:redirect_to) { should start_with(client.default_callback_uri) }
        end

        context 'with a bad :redirect_uri' do
          let(:params) { valid.merge(redirect_uri: 'http://c') }
          its(:redirect?) { should eq(false) }
          its(:redirect_to) { should be_nil }
          its(:error) { should match(/redirect_uri/) }
        end

        context 'with a bad :client_id' do
          let(:params) { valid.merge(client_id: nil) }
          its(:redirect?) { should eq(false) }
          its(:redirect_to) { should be_nil }
          its(:error) { should match(/client_id/) }
        end

        context 'with a bad :response_type' do
          let(:params) { valid.merge(response_type: 'xxxx') }
          its(:redirect?) { should eq(true) }
          its(:redirect_to) { should have_fragment({ error: :unsupported_response_type }) }
          its(:error) { should match(/response_type/) }
        end

        context 'with a bad :scope', skip: true do
          let(:params) { valid.merge(scope: 'a:b:c') }
          its(:redirect?) { should eq(true) }
          its(:redirect_to) { should have_fragment({ error: :invalid_scope }) }
          its(:error) { should match(/scope/) }
        end

      end

      context 'when the client has grants for all scopes' do
      end

      context 'when the client is missing scope grants' do
      end

      context 'when the user is not authorized to grant all scopes' do
      end

    end
  end
end

