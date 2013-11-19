require_relative '../../lib/config'
require_relative '../../lib/models'
require_relative '../../lib/errors'

module Evercam
  class APIv1 < Grape::API

    default_format :json

    rescue_from NotFoundError do |e|
      error_response({ status: 404, message: e.message })
    end

    rescue_from ForbiddenError do |e|
      error_response({ status: 403, message: e.message })
    end

  end
end

require_relative './v1/routes/snapshots'

