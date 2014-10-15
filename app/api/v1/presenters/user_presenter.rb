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

      expose :firstname, documentation: {
        type: 'string',
        desc: 'Users first name',
        required: true
      }

      expose :lastname, documentation: {
        type: 'string',
        desc: 'Users last name',
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
        desc: 'Two letter <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements">ISO country code</a>',
        required: true
      } do |u,o|
        u.country.iso3166_a2
      end

    end
  end
end

