require_relative './presenter'

module Evercam
  module Presenters
    class Log < Presenter

      root :logs

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

