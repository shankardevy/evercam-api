require 'data_helper'

module Evercam
   module Actors
      describe ShareDelete do
         let(:share) {
            create(:private_camera_share)
         }

         let(:rights) {
            AccessRightSet.for(share.camera, share.user)
         }

         subject {
            ShareDelete
         }

         before(:each) do
            list = []
            AccessRight::BASE_RIGHTS.each do |right|
               list << right << "#{AccessRight::GRANT}~#{right}"
            end
            rights.grant(*list)
         end

         context 'when given valid parameters' do
            let(:parameters) {
               {id: share.camera.exid, share_id: share.id}
            }

            it 'returns success and updates the shares permissions' do
               outcome = subject.run(parameters)
               expect(outcome).to be_success
               result = outcome.result
               expect(result).not_to be_nil
               expect(result).to eq(false)
               expect(rights.allow?(AccessRight::LIST)).to eq(false)
               expect(rights.allow?(AccessRight::EDIT)).to eq(false)
               expect(rights.allow?(AccessRight::DELETE)).to eq(false)
               expect(rights.allow?(AccessRight::VIEW)).to eq(false)
               expect(rights.allow?(AccessRight::SNAPSHOT)).to eq(false)
               expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::LIST}")).to eq(false)
               expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::EDIT}")).to eq(false)
               expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::DELETE}")).to eq(false)
               expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::VIEW}")).to eq(false)
               expect(rights.allow?("#{AccessRight::GRANT}~#{AccessRight::SNAPSHOT}")).to eq(false)
            end
         end

         context 'when given an invalid camera id' do
            let(:parameters) {
               {id: 'non_existent_camera', share_id: share.id}
            }

            it 'returns an error' do
               outcome = subject.run(parameters)
               errors = outcome.errors.symbolic
               expect(outcome).to_not be_success
               expect(errors[:camera]).to eq(nil)
            end
         end

         context 'returns success when given a non-existent share id' do
            let(:parameters) {
               {id: share.camera.exid, share_id: -1000}
            }

            it 'returns an error' do
               outcome = subject.run(parameters)
               expect(outcome).to be_success
               result = outcome.result
               expect(result).not_to be_nil
               expect(result).to eq(false)
            end
         end
      end
   end
end