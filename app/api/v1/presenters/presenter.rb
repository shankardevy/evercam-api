module Evercam
  class Presenter < Grape::Entity

    format_with(:timestamp) { |t| t.to_i }

  end
end

