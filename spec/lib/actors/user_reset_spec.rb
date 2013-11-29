require 'data_helper'
require_lib 'actors'

module Evercam
  module Actors
    describe UserReset do

      let(:user) { create(:user) }

      let(:valid) do
        {
          username: user.username,
          password: 'password123',
          confirmation: 'password123'
        }
      end

    end
  end
end

