require 'rack_helper'
require_app 'api/v1'

describe 'API routes/models' do

  let(:app) { Evercam::APIv1 }

  let!(:model0) { create(:vendor_model, name: VendorModel::DEFAULT, config: {username:'aaa', password: 'xxx'}) }
  let!(:vendor0) { model0.vendor }
  let!(:model1) { create(:vendor_model, vendor: vendor0, name: 'v1', config: {jpg: '/aaa/snap', password: 'yyy'}) }
  let!(:vendor1) { create(:vendor) }

  let(:user) { create(:user) }
  let(:api_keys) { {api_id: user.api_id, api_key: user.api_key} }


  # TODO - write tests for new endpoints

end

