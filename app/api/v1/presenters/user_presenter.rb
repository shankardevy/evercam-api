require_relative './presenter'

module Evercam
  class UserPresenter < Presenter

    root :users

    expose :id do |u,o|
      u.username
    end

    expose :forename
    expose :lastname
    expose :username
    expose :email

    expose :country do |u,o|
      u.country.iso3166_a2
    end

    with_options(format_with: :timestamp) do
      expose :created_at
      expose :updated_at
      expose :confirmed_at
    end

  end
end

