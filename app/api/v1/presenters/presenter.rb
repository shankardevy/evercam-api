module Evercam
  class Presenter < Grape::Entity

    format_with(:timestamp) { |t| t.to_i }

    def to_json(state)
      opts = state.to_h if state && state.respond_to?(:to_h)
      JSON.pretty_generate(serializable_hash(opts), state)
    end

  end
end

