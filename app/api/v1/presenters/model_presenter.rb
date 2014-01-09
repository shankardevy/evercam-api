require_relative './presenter'

module Evercam
  class ModelPresenter < Presenter

    root :models

    expose :vendor do |m,o|
      m.vendor.exid
    end

    expose :name, :known_models

    expose :config, as: :defaults

  end
end

