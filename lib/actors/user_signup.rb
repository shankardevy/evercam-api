module Evercam
  module Actors

    class UserSignup < Mutations::Command

      required do
        string :forename
        string :lastname
        string :username
        string :country
        string :email
      end

      def execute
        if User.by_login(username)
          add_error(:username, :exists, 'the supplied username is already registered')
        end

        if User.by_login(email)
          add_error(:email, :exists, 'the supplied email is already registered')
        end

        unless country = Country.by_iso3166(inputs[:country])
          add_error(:country, :invalid, 'the supplied country code does not exist')
        end

        return nil if has_errors?
        pass = SecureRandom.hex(16)

        User.create(inputs.merge(password: pass, country: country)).tap do |user|
          Mailers::UserMailer.confirm(user: user, password: pass)
        end
      end

    end
  end
end

