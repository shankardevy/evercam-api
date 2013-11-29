module Evercam
  module Actors
    class UserReset < Mutations::Command

      required do
        string :username
        string :password
        string :confirmation
      end

    end
  end
end

