require_relative './presenter'

module Evercam
  module Presenters
    class CameraShareRequest < Presenter

      root :share_requests

      expose :id,
             documentation: {
                type: 'string',
                desc: 'Unique identifier for a camera share request.',
                required: true
             } do |s, o|
        s.key
      end

      expose :camera_id,
             documentation: {
                type: 'string',
                desc: 'Unique identifier of the camera to be shared.',
                required: true
             } do |s, o|
        s.camera.exid
      end

      expose :user_id,
             documentation: {
                type: 'string',
                desc: 'The unique identifier of the user who shared the camera.',
                required: true
             } do |s,o|
         s.user.username
      end

      expose :email,
             documentation: {
                type: 'string',
                desc: 'The email address of the user the camera is shared with.',
                required: true
             }

      expose :rights,
             documentation: {
               type: 'string',
               desc: "A comma separated list of the rights to be granted on the share.",
               required: true
               } do |s, o|
        s.rights.split(",").inject([]) do |list, entry|
          list << entry.strip.capitalize
        end.join(",")
      end
    end
  end
end