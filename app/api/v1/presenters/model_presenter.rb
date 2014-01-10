require_relative './presenter'

module Evercam
  module Presenters
    class Model < Presenter

      root :models

      expose :vendor, documentation: {
        type: 'string',
        desc: 'Unique identifier for the vendor',
        required: true
      } do |m,o|
        m.vendor.exid
      end

      expose :name, documentation: {
        type: 'string',
        desc: 'Name of the model',
        required: true
      }

      expose :known_models, documentation: {
        type: 'array',
        desc: 'String array of all models known to share the same defaults',
        required: true,
        items: {
          type: 'string'
        }
      }

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

