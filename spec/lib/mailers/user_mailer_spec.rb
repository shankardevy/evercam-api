require 'data_helper'
require_lib 'mailers'

module Evercam
  module Mailers
    describe UserMailer do

      let(:user) { create(:user) }

      subject { UserMailer }

      describe '#confirm' do
        it 'renders the content correctly' do
          mailer = subject.new(user: user, password: 'xxxx')
          result = mailer.confirm

          expect(result[:to]).to eq(user.email)
          expect(result[:subject]).to match(/confirm/i)
          expect(result[:body]).to match(/xxxx/)
        end
      end

    end
  end
end

