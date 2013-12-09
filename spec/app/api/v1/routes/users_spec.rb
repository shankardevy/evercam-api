require 'rack_helper'
require_app 'api/v1'

describe 'API routes/users' do

  let(:app) { Evercam::APIv1 }

  let(:params) do
    {
      forename: 'Garrett',
      lastname: 'Heaver',
      username: 'garrettheaver',
      email: 'garrett@evercam.io',
      country: 'ie'
    }
  end

  describe 'POST /users' do

    context 'when the params are valid' do
      it 'creates the user and returns the json' do
        post('/users', params)

        expect(last_response.status).to eq(201)
        response0 = last_response.json['users'][0]

        expect(response0.keys).
          to eq(['id', 'forename', 'lastname', 'username', 'email',
                 'country', 'created_at', 'updated_at', 'confirmed_at'])
      end
    end

  end

end

