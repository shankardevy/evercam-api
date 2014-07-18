module Evercam
  module Actors
    class TokenSet < Mutations::Command

      required do
        string :username
        string :token
      end

      def validate
        #unless user = User.by_login(username)
        #  add_error(:username, :exists, 'Username does not exist')
        #end
      end

      def execute
        t = Time.now
        expires = t + 1.hour

        # User.by_login(user.username).update(reset_token: token, token_expires_at: expires)
        user = User.by_login(username).update(reset_token: token, token_expires_at: expires)
        
        user
      end

    end
  end
end