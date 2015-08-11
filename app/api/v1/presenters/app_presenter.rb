require_relative './presenter'

module Evercam
  module Presenters
    class App < Presenter

      root :apps

      expose :local_recording,
        documentation: {
        type: 'Boolean',
        desc: 'The status of the local recording app.',
        required: true
      }

      expose :cloud_recording,
        documentation: {
        type: 'boolean',
        desc: 'the status of the cloud recording app.',
        required: true
      }

      expose :motion_detection,
        documentation: {
        type: 'Boolean',
        desc: 'The status of the motion detection app.',
        required: true
      }

      expose :watermark,
        documentation: {
        type: 'Boolean',
        desc: 'The status of the watermark app.',
        required: true
      }
    end
  end
end
