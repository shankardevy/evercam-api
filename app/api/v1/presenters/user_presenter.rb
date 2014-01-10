require_relative './presenter'

module Evercam
  module Presenters
    class User < Presenter

      root :users

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique Evercam username',
        required: true
      } do |u,o|
        u.username
      end

      with_options(format_with: :timestamp) do

        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation',
          required: true
        }

        expose :updated_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at last update',
          required: true
        }

        expose :confirmed_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at account confirmation',
          required: true
        }

      end

      expose :forename, documentation: {
        type: 'string',
        desc: 'Users forename',
        required: true
      }

      expose :lastname, documentation: {
        type: 'string',
        desc: 'Users lastname',
        required: true
      }

      expose :username, documentation: {
        type: 'string',
        desc: 'Unique Evercam username',
        required: true
      }

      expose :email, documentation: {
        type: 'string',
        desc: 'Users email address',
        required: true
      }

      expose :country, documentation: {
        type: 'string',
        desc: 'Two letter ISO country code',
        required: true
      } do |u,o|
        u.country.iso3166_a2
      end

    end
  end
end

