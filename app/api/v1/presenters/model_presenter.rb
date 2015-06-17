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

      # expose :specs, documentation: {
      #   type: 'hash',
      #   desc: 'Device specifications of this camera model',
      #   required: true
      # } do |m,o|
      #   m.specs
      # end

      expose :images do
        expose :icon, documentation: {
          type: 'String',
          desc: 'Model icon'
        } do |m,o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/icon.jpg"
        end

        expose :thumbnail, documentation: {
          type: 'String',
          desc: 'Model thumbnail'
        } do |m,o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/thumbnail.jpg"
        end

        expose :original, documentation: {
          type: 'String',
          desc: 'Model Original'
        } do |m,o|
          "http://evercam-public-assets.s3.amazonaws.com/#{m.vendor.exid}/#{m.exid}/original.jpg"
        end
      end

    end
  end
end

