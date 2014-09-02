require_relative './presenter'

module Evercam
  module Presenters
    class Webhook < Presenter

      root :webhooks

      expose :id,
             documentation: {
               type: 'integer',
               desc: 'Unique identifier of the webhook.',
               required: true
             } do |s, o|
        s[:exid]
      end

      expose :camera_id,
             documentation: {
               type: 'string',
               desc: 'Unique identifier of the camera.',
               required: true
             } do |s, o|
        s.camera.exid
      end

      expose :url,
             documentation: {
               type: 'string',
               desc: 'Url which will receive webhook data.',
               required: true
             }

    end
  end
end

