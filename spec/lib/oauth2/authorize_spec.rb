require 'rack_helper'
require_lib 'oauth2'

module Evercam
  module OAuth2
    describe Authorize do

      let(:user0) { create(:user) }

      let(:camera0) { create(:camera, owner: user0) }

      let(:client0) { create(:client, callback_uris: ['http://a', 'http://b']) }

      let(:token0) { create(:access_token, grantor: user0, grantee: client0) }

      let(:camera_right0) { create(:camera_right, token: token0, camera: camera0) }

      subject { Authorize.new(user0, params) }

      let(:valid) do
        {
          response_type: 'token',
          client_id: client0.exid,
          redirect_uri: client0.default_callback_uri,
          scope: "camera:#{camera_right0.name}:#{camera0.exid}"
        }
      end

      context 'when the request is invalid' do

        it 'returns false from #valid? for any form on error' do
          params = valid.merge(response_type: 'xxxx')
          request = Authorize.new(user0, params)
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
          its(:redirect_to) { should start_with(client0.default_callback_uri) }
        end

        context 'with no params at all' do
          let(:params) { {} }

          its(:redirect?) { should eq(false) }
          its(:redirect_to) { should be_nil }
          its(:error) { should match(/client_id/) }
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

        context 'with a bad :scope' do
          let(:params) { valid.merge(scope: 'a:b:c') }

          its(:redirect?) { should eq(true) }
          its(:redirect_to) { should have_fragment({ error: :invalid_scope }) }
          its(:error) { should match(/scope/) }
        end

      end

      context 'when the user is not authorized to grant all scopes' do
        subject { Authorize.new(create(:user), valid) }

        its(:valid?) { should eq(false) }
        its(:redirect?) { should eq(true) }
        its(:redirect_to) { should have_fragment({ error: :access_denied }) }
        its(:error) { should match(/cannot grant/) }
      end

      context 'when the client has grants for all scopes' do

        let(:params) { valid }

        before(:each) { subject }

        let(:token1) { client0.tokens.order(:id).last }

        it 'creates a new access token for the client' do
          expect(token1).to_not eq(token0)
          expect(client0.reload.tokens.count).to eq(2)
        end

        it 'create the new rights for the token' do
          count = camera0.permissions.
            where(token: token1, name: camera_right0.name).count

          expect(count).to eq(1)
        end

        its(:valid?) { should eq(true) }
        its(:redirect?) { should eq(true) }
        its(:missing) { should be_empty }

        its(:redirect_to) { should have_fragment({
          access_token: token1.request,
          expires_in: token1.expires_in,
          token_type: :bearer
        }) }

      end

      context 'when the client is missing scope grants' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:params) do
          valid.merge(scope: [
            "camera:#{camera_right0.name}:#{camera0.exid}",
            "camera:#{camera_right0.name}:#{camera1.exid}"
          ].join(','))
        end

        its(:valid?) { should eq(true) }
        its(:redirect?) { should eq(false) }

        it 'returns the missing scopes' do
          expect(subject.missing.size).to eq(1)
          expect(subject.missing[0].resource).
            to eq(camera1)
        end

      end

      context 'when the client approves the missing scopes' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:params) do
          valid.merge(scope: [
            "camera:#{camera_right0.name}:#{camera0.exid}",
            "camera:#{camera_right0.name}:#{camera1.exid}"
          ].join(','))
        end

        let(:token1) { client0.tokens.order(:id).last }

        before(:each) { subject.approve! }

        it 'creates a new access token for the client' do
          expect(token1).to_not eq(token0)
          expect(client0.reload.tokens.count).to eq(2)
        end

        it 'create the new rights for the token' do
          count = CameraRight.where(token: token1).count
          expect(count).to eq(2)
        end

        its(:redirect?) { should eq(true) }
        its(:redirect_to) { should have_fragment({ access_token: token1.request }) }

      end

      context 'when the client declines the missing scopes' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:params) do
          valid.merge(scope: [
            "camera:#{camera_right0.name}:#{camera1.exid}"
          ].join(','))
        end

        before(:each) { subject.decline! }

        its(:redirect?) { should eq(true) }
        its(:redirect_to) { should have_fragment({ error: :access_denied }) }
        its(:error) { should match(/denied/) }

      end

    end
  end
end

