require_relative './presenter'

module Evercam
  class VendorPresenter < Presenter

    root :vendors

    expose :exid, as: :id

    expose :name

    expose :known_macs

    expose :is_supported, if: { supported: true } do |v,o|
      false == v.firmwares.empty?
    end

    expose :models, if: { models: true } do |v,o|
      v.firmwares.map(&:known_models).flatten
    end

  end
end

