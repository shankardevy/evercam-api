require_relative './presenter'
require 'base64'

module Evercam
  module Presenters
    class Snapshot < Presenter

      root :snapshots

      expose :created_at, documentation: {
        type: 'integer',
        desc: 'Snapshot timestamp',
        required: false
      } do |s,o|
        s.created_at.to_i
      end

      expose :notes, documentation: {
        type: 'string',
        desc: 'Note for snapshot',
        required: false
      }

      expose :data, if: { with_data: true }, documentation: {
        type: 'file',
        desc: 'Image data',
        required: false
      } do |s,o|
        data = Base64.encode64(s.data).gsub("\n", '')
        "data:image/jpeg;base64,#{data}"
      end

    end
  end
end

