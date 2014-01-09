require_relative './presenter'

module Evercam
  class StreamPresenter < Presenter

    root :streams

    expose :name, as: :id
    expose :is_public

    with_options(format_with: :timestamp) do
      expose :created_at
      expose :updated_at
    end

    expose :owner do |s,o|
      s.owner.username
    end

    expose :endpoints do |s,o|
      s.config['endpoints']
    end

    expose :snapshots do |s,o|
      s.config['snapshots']
    end

    expose :auth do |s,o|
      s.config['auth']
    end

  end
end

