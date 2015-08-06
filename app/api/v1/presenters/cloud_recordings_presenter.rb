require_relative './presenter'

module Evercam
  module Presenters
    class CloudRecording < Presenter

      root :cloud_recordings

      expose :storage_duration,
        documentation: {
        type: 'integer',
        desc: '',
        required: true
      }

      expose :schedule,
        documentation: {
        type: 'array',
        desc: '',
        required: true
      }
    end
  end
end
