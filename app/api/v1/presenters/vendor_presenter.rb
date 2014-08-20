require_relative './presenter'

module Evercam
  module Presenters
    class Vendor < Presenter

      root :vendors

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique identifier for the vendor',
        required: true
      } do |v,o|
        v.exid
      end

      expose :name, documentation: {
        type: 'string',
        desc: 'Name of the vendor',
        required: true
      }

      expose :known_macs, documentation: {
        type: 'array',
        desc: 'String array of MAC prefixes the vendor uses',
        required: true,
        items: {
          type: 'string'
        }
      }

    end
  end
end

