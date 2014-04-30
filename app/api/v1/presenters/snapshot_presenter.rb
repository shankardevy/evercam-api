require_relative './presenter'
require 'base64'

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
        type: 'integer',
        desc: 'Snapshot timestamp',
        required: false
      } do |s,o|
        s.created_at.to_i
      end

      expose :timezone, documentation: {
        type: 'string',
        desc: 'Name of the <a href="http://en.wikipedia.org/wiki/List_of_tz_database_time_zones">IANA/tz</a> timezone where this camera is located',
        required: true
      } do |s,o|
        s.camera.timezone.zone
      end

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

