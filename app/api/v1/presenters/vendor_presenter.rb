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

      expose :is_supported, if: { supported: true }, documentation: {
        type: 'boolean',
        desc: 'Whether or not this vendor produces Evercam supported cameras',
      } do |v,o|
        false == v.vendor_models.empty?
      end

      expose :models, if: { models: true }, documentation: {
        type: 'array',
        desc: 'String array of models currently known for this vendor',
        items: {
          type: 'string'
        }
      } do |v,o|
        v.vendor_models.map(&:known_models).flatten
      end

    end
  end
end

