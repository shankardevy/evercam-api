module Evercam
  module Actors
    class PasswordReset < Mutations::Command

      required do
        string :username
        string :password
        string :confirmation
      end

      def validate
        unless user = User.by_login(username)
          add_error(:username, :exists, 'Username does not exist')
        end

        unless password == confirmation
          add_error(:confirmation, :match, 'Confirmation must match password')
        end
      end

      def execute
        user = User.by_login(username).
          set(password: password).save
      end

    end
  end
end