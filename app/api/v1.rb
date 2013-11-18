module Evercam
  class APIv1 < Grape::API

    default_format :json

  end
end

require_relative './v1/routes/snapshots'

