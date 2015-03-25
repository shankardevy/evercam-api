require 'data_helper'

module Evercam
   module Actors
      describe ShareUpdate do
         let(:share) {
            create(:private_camera_share)
         }

         let(:rights) {
            AccessRightSet.for(share.camera, share.user)
         }

         subject {
            ShareUpdate
         }

         before(:each) do
            rights.grant(AccessRight::VIEW, AccessRight::SNAPSHOT, AccessRight::LIST)
         end

         context 'when given valid parameters' do
            let(:parameters) {
               {id: share.id, rights: "list,edit,delete"}
            }

            it 'returns success and updates the shares permissions' do
               pending
               outcome = subject.run(parameters)
               expect(outcome).to be_success
               result = outcome.result
               expect(result).not_to be_nil
               expect(result.class).to eq(CameraShare)
               expect(rights.allow?(AccessRight::LIST)).to eq(true)
               expect(rights.allow?(AccessRight::EDIT)).to eq(true)
               expect(rights.allow?(AccessRight::DELETE)).to eq(true)
               expect(rights.allow?(AccessRight::VIEW)).to eq(false)
               expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
            end
         end

         context 'when given an invalid share identifier' do
            let(:parameters) {
               {id:     -1000,
                rights: "list,view"}
            }

            it 'returns an error' do
               pending
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:camera_share]).to eq(:exists)
            end
         end

         context 'when given an invalid rights' do
            let(:parameters) {
               {id:      share.id,
                rights:  "list,blah,view"}
            }

            it 'returns an error' do
               pending
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:rights]).to eq(:valid)
            end
         end
      end
   end
end
