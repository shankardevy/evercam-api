require_relative './presenter'

module Evercam
  module Presenters
    class Model < Presenter

      root :models

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique identifier of the model',
        required: true
      } do |m|
        m.exid
      end

      expose :name, documentation: {
        type: 'string',
        desc: 'Name of the model',
        required: true
      }

      expose :vendor_id, documentation: {
        type: 'string',
        desc: 'Unique identifier for the vendor',
        required: true
      } do |m, o|
        m.vendor.exid
      end

      expose :defaults, documentation: {
        type: 'hash',
        desc: 'Various default values used by this camera model',
        required: true
      } do |m,o|
        m.config
      end

    end
  end
end

