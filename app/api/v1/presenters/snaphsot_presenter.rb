require_relative './presenter'

module Evercam
  module Presenters
    class Snapshot < Presenter

      root :snapshots

      expose :camera, documentation: {
        type: 'string',
        desc: 'Unique Evercam identifier for the camera',
        required: true
      } do |s,o|
        s.camera.exid
      end

      expose :notes, documentation: {
        type: 'string',
        desc: 'Note for snapshot',
        required: false
      }

      expose :created_at, documentation: {
        type: 'string',
        desc: 'Snapshot timestamp',
        required: false
      }

    end
  end
end

