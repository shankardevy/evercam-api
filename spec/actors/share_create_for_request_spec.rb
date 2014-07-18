require 'data_helper'

module Evercam
   module Actors
      describe ShareCreateForRequest do
         let(:user) {
            create(:user)
         }

         let(:share_request) {
            create(:camera_share_request, email: user.email)
         }

         let(:camera) {
            share_request.camera
         }

         subject {
            ShareCreateForRequest
         }

         context 'when given valid parameters' do
            let(:parameters) {
               {key:    share_request.key,
                email:  user.email}
            }

            it 'creates a share with the requesting user as the sharer' do
               outcome = subject.run(parameters)
               expect(outcome).to be_success
               result = outcome.result
               expect(result).not_to be_nil
               expect(result.class).to eq(CameraShare)
               expect(result.sharer_id).to eq(share_request.user.id)
               share_request.reload
               expect(share_request.status).to eq(CameraShareRequest::USED)
            end
         end

         context 'when given an invalid key' do
            let(:parameters) {
               {key:    SecureRandom.hex(25),
                email:  user.email}
            }

            it 'returns an error' do
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:camera_share_request]).to eq(:exists)
            end
         end

         context 'when the email address specified does not match the request email' do
            let(:parameters) {
               {key:    share_request.key,
                email:  "lalala@blah.com"}
            }

            it 'returns an error' do
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:email]).to eq(:invalid)
            end
         end
      end
   end
end