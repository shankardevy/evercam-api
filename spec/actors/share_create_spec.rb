require 'data_helper'

module Evercam
   module Actors
      describe ShareCreate do
         let(:private_camera) {
            create(:camera, is_public: false)
         }

         let(:public_camera) {
            create(:camera, is_public: true)
         }

         let(:user) {
            create(:user)
         }

         subject {
            ShareCreate
         }

         context 'when given valid parameters' do
            context 'for a user that already exists in the system' do
               let(:parameters) {
                  {id:     private_camera.exid,
                   email:  user.email,
                   rights: "list,view"}
               }

               context 'that do not include a grantor' do
                  it 'creates a share with the camera owner as the sharer' do
                     outcome = subject.run(parameters)
                     expect(outcome).to be_success
                     result = outcome.result
                     expect(result).not_to be_nil
                     expect(result.class).to eq(CameraShare)
                     expect(result.sharer_id).to eq(private_camera.owner.id)
                  end
               end

               context 'that do include a grantor' do
                  it 'create a share with the grantor as the sharer' do
                     grantor = create(:user)
                     parameters[:grantor] = grantor.username
                     outcome = subject.run(parameters)
                     expect(outcome).to be_success
                     result = outcome.result
                     expect(result).not_to be_nil
                     expect(result.class).to eq(CameraShare)
                     expect(result.sharer_id).to eq(grantor.id)
                  end
               end

               it 'creates a private share for a private camera' do
                  outcome = subject.run(parameters)
                  expect(outcome).to be_success
                  result = outcome.result
                  expect(result).not_to be_nil
                  expect(result.class).to eq(CameraShare)
                  expect(result.kind).to eq(CameraShare::PRIVATE)
               end

               it 'creates a private share for a public camera' do
                  parameters[:id] = public_camera.exid
                  outcome = subject.run(parameters)
                  expect(outcome).to be_success
                  result = outcome.result
                  expect(result).not_to be_nil
                  expect(result.class).to eq(CameraShare)
                  expect(result.kind).to eq(CameraShare::PRIVATE)
               end
            end

            context 'for a user that does not exists in the system' do
               let(:parameters) {
                  {id:     private_camera.exid,
                   email:  "some.user@nowhere.com",
                   rights: "list,view"}
               }

               context 'that do not include a grantor' do
                  it 'creates a share with the camera owner as the sharer' do
                     outcome = subject.run(parameters)
                     expect(outcome).to be_success
                     result = outcome.result
                     expect(result).not_to be_nil
                     expect(result.class).to eq(CameraShareRequest)
                     expect(result.user_id).to eq(private_camera.owner.id)
                  end
               end

               context 'that do include a grantor' do
                  it 'create a share with the grantor as the sharer' do
                     grantor = create(:user)
                     parameters[:grantor] = grantor.username
                     outcome = subject.run(parameters)
                     expect(outcome).to be_success
                     result = outcome.result
                     expect(result).not_to be_nil
                     expect(result.class).to eq(CameraShareRequest)
                     expect(result.user_id).to eq(grantor.id)
                  end
               end
            end
         end

         context 'when given an invalid camera identifier' do
            let(:parameters) {
               {id:     "no_such_camera",
                email:  user.email,
                rights: "list,view"}
            }

            it 'returns an error' do
               expect {
                  subject.run(parameters)
               }.to raise_error(Evercam::NotFoundError, "Unable to locate the 'no_such_camera' camera.")
            end
         end

         context 'when given an invalid grantor user name' do
            let(:parameters) {
               {id:      private_camera.exid,
                email:   user.email,
                rights:  "list,view",
                grantor: "this_is_not_a_valid_user_name"}
            }

            it 'returns an error' do
               expect {
                  subject.run(parameters)
               }.to raise_error(Evercam::NotFoundError, "Unable to locate a user for 'this_is_not_a_valid_user_name'.")
            end
         end

         context 'when given an invalid rights' do
            let(:parameters) {
               {id:      private_camera.exid,
                email:   user.email,
                rights:  "list,blah,view"}
            }

            it 'returns an error' do
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:rights]).to eq(:valid)
            end
         end

         context 'when a camera share request already exists for the email address' do
            let!(:share_request) {
               create(:camera_share_request, camera: private_camera, email: "some.user@nowhere.com")
            }
            let(:parameters) {
               {id:     private_camera.exid,
                email:  "some.user@nowhere.com",
                rights: "list,view"}
            }

            it 'raises an exception' do
               expect {
                  subject.run(parameters)
               }.to raise_error(Evercam::ConflictError, "A share request already exists for the 'some.user@nowhere.com' email address for this camera.")
            end
         end

         context 'when a camera share already exists for the user' do
            let!(:share) {
               create(:private_camera_share, camera: private_camera, user: user)
            }

            context 'using their email address' do
               let(:parameters) {
                  {id:     private_camera.exid,
                   email:  user.email,
                   rights: "list,view"}
               }

               it 'raises an exception' do
                  expect {
                     subject.run(parameters)
                  }.to raise_error(Evercam::ConflictError, "The camera has already been shared with this user.")
               end
            end

            context 'using their user name' do
               let(:parameters) {
                     {id:     private_camera.exid,
                      email:  user.username,
                      rights: "list,view"}
                  }

               it 'raises an exception' do
                  expect {
                     subject.run(parameters)
                  }.to raise_error(Evercam::ConflictError, "The camera has already been shared with this user.")
               end
            end
         end

         context 'when given an invalid email address' do
            context 'for a camera share request' do 
               let(:parameters) {
                  {id:      private_camera.exid,
                   email:   "blah.blah.com",
                   rights:  "list,view"}
               }

               it 'raises an exception' do
                  expect {subject.run(parameters)}.to raise_error(Evercam::BadRequestError, "Invalid email address specified.")
               end
            end
         end
      end
   end
end