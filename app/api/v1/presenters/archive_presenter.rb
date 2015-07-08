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
        desc: 'Archive title',
        required: true
      }

      with_options(format_with: :timestamp) do
        expose :from_date, documentation: {
          type: 'integer',
          desc: 'Unix timestamp archive start from',
          required: true
        }

        expose :to_date, documentation: {
          type: 'integer',
          desc: 'Unix timestamp archive end to',
          required: true
        }

        expose :created_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp at creation',
          required: false
        }
      end

      expose :status, documentation: {
        type: 'integer',
        desc: 'Archive status',
        required: true
      }

      expose :requested_by, documentation: {
        type: 'string',
        desc: 'Evercam username who requested archive',
        required: true
      } do |a, _o|
        a.user.username
      end

      expose :embed_time, documentation: {
        type: 'boolean',
        desc: 'Whether or not timestamp overlay of archive',
        required: false
      }
      expose :public, documentation: {
        type: 'boolean',
        desc: 'Available archive public',
        required: false
      }
    end
  end
end
