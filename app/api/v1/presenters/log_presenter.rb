require_relative './presenter'

module Evercam
  module Presenters
    class Log < Presenter

      root :logs

      expose :who, documentation: {
        type: 'string',
        desc: 'Username or Client name ',
        required: true
      } do |c,o|
        if c.access_token.nil?
          "Anonymous"
        elsif c.access_token.user.present?
          c.access_token.user.fullname
        elsif c.access_token.client.present?
          c.access_token.client.exid
        end
      end

      expose :action, documentation: {
        type: 'string',
        desc: 'Camera action',
        required: true
      }

      with_options(format_with: :timestamp) do
        expose :done_at, documentation: {
          type: 'integer',
          desc: 'Unix timestamp of the action',
          required: true
        }
      end

    end
  end
end

