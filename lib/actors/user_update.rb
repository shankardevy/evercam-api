require_relative '../workers'

module Evercam
  module Actors
    class UserUpdate < Mutations::Command

      required do
        string :id
      end

      optional do
        string :forename
        string :lastname
        string :country
        string :email
      end

      def validate
        if email and User.by_login(email)
          add_error(:email, :exists, 'Email is already registered')
        end

        if country and not Country.by_iso3166(inputs[:country])
          add_error(:country, :invalid, 'Country is invalid')
        end
      end

      def execute
        user = User.by_login(id)
        user.forename = forename if forename
        user.lastname = lastname if lastname
        user.country = Country.by_iso3166(inputs[:country]) if country
        user.email = email if email
        user.save
      end

    end
  end
end

