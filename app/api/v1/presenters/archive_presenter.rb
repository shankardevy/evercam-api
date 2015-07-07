require_relative './presenter'

module Evercam
  module Presenters
    class Archive < Presenter
      root :archives

      expose :id, documentation: {
        type: 'string',
        desc: 'Unique archive id',
        required: true
      } do |a, _o|
        a.exid
      end

      expose :camera_id, documentation: {
        type: 'string',
        desc: 'Unique camera id',
        required: true
      } do |a, _o|
        a.camera.exid
      end

      expose :title, documentation: {
        type: 'string',
        desc: 'Clip title',
        required: true
      }

      expose :url, documentation: {
        type: 'string',
        desc: 'Clip URL',
        required: false
      }

      expose :notes, documentation: {
        type: 'string',
        desc: 'Clip notes',
        required: false
      }

      with_options(format_with: :timestamp) do
        expose :from_date, documentation: {
          type: 'integer',
          desc: 'Unix timestamp clip start from',
          required: true
        }

        expose :to_date, documentation: {
          type: 'integer',
          desc: 'Unix timestamp clip end to',
          required: true
        }

        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation',
          required: true
        }
      end

      expose :status, documentation: {
        type: 'integer',
        desc: 'Clip status',
        required: true
      }

      expose :requested_by, documentation: {
        type: 'string',
        desc: 'Evercam username who requested clip',
        required: true
      } do |a, _o|
        a.user.username
      end

      expose :number_of_frames, documentation: {
        type: 'integer',
        desc: 'Total number of frames in clip',
        required: true
      }

      expose :embed_time, documentation: {
        type: 'boolean',
        desc: 'Whether or not timestamp overlay of clip',
        required: true
      }

    end
  end
end
