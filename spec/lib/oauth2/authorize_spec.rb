require 'rack_helper'
require_lib 'oauth2'

module Evercam
  module OAuth2
    describe Authorize do

      let(:user0) { create(:user) }

      let(:camera0) { create(:camera, owner: user0) }

      let(:client0) { create(:client, callback_uris: ['http://a', 'http://b']) }

      subject { Authorize.new(user0, params) }

      let(:valid) do
        {
          response_type: 'token',
          client_id: client0.exid,
          redirect_uri: client0.default_callback_uri,
          scope: "camera:view:#{camera0.exid}"
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

      context 'when the user has previously granted for all scopes to this client' do

        let(:params) { valid }

        before(:each) do
          create(
            :access_token,
            grantee: client0,
            grantor: user0
          ).tap do |t|
            t.add_right(name: params[:scope])
          end
        end

        it 'creates a new access token for the client' do
          expect(subject.client.reload.tokens.count).to eq(2)
        end

        it 'adds all the requested scopes to the new token' do
          expect(subject.token.rights.count).to eq(1)
        end

        it 'wants to redirect' do
          expect(subject).to be_redirect
        end

        it 'is a valid request' do
          expect(subject).to be_valid
        end

        it 'does not have any missing scopes' do
          expect(subject.missing).to eq([])
        end

        it 'includes the token in the redirect fragment' do
          expect(subject.redirect_to).to have_fragment({
            access_token: subject.token.request,
            expires_in: subject.token.expires_in,
            token_type: :bearer
          })
        end

      end

      context 'when the client is missing scope grants' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:scopes) do
          [
            "camera:view:#{camera0.exid}",
            "camera:view:#{camera1.exid}"
          ]
        end

        let(:params) do
          valid.merge(scope: scopes.join(','))
        end

        it 'is a valid request' do
          expect(subject).to be_valid
        end

        it 'does not want to redirect' do
          expect(subject).to_not be_redirect
        end

        it 'returns the missing scopes' do
          expect(subject.missing.size).to eq(2)
        end

        it 'ignores any grants by other users' do
          token = create(:access_token, grantee: client0)
          scopes.each { |s| token.add_right(name: s) }
          expect(subject.missing.size).to eq(2)
        end

      end

      context 'when the request is for generic scopes' do

        let(:params) do
          valid.merge(scope: 'cameras:view:all')
        end

        it 'is a valid request' do
          expect(subject).to be_valid
        end

        it 'does not want to redirect' do
          expect(subject).to_not be_redirect
        end

        it 'returns the missing scopes' do
          expect(subject.missing.size).to eq(1)
        end

      end

      context 'when the client approves the missing scopes' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:params) do
          valid.merge(scope: [
            "camera:view:#{camera0.exid}",
            "camera:view:#{camera1.exid}"
          ].join(','))
        end

        before(:each) { subject.approve! }

        it 'creates a new access token for the client' do
          expect(subject.client.reload.tokens.count).to eq(1)
        end

        it 'create the new rights for the token' do
          expect(subject.token.rights.count).to eq(2)
        end

        it 'wants to redirect the client' do
          expect(subject).to be_redirect
        end

        it 'includes the token in the redirect fragment' do
          expect(subject.redirect_to).to have_fragment({
            access_token: subject.token.request,
            expires_in: subject.token.expires_in,
            token_type: :bearer
          })
        end

      end

      context 'when the client declines the missing scopes' do

        let(:camera1) do
          create(:camera, owner: user0)
        end

        let(:params) do
          valid.merge(scope: [
            "camera:view:#{camera1.exid}"
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

