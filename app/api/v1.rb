require_relative '../../lib/withnail'
require_relative '../../lib/formatters'

module Evercam
  class APIv1 < Grape::API

    include WebErrors

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    default_format :json

    error_formatter :json, Formatters::JSONError
    formatter :json, Formatters::JSONObject

    rescue_from AuthenticationError do |e|
      error_response({ status: 401, message: e.message })
    end

    rescue_from AuthorizationError do |e|
      error_response({ status: 403, message: e.message })
    end

    rescue_from NotFoundError do |e|
      error_response({ status: 404, message: e.message })
    end

    helpers do
      def auth
        Withnail::WithAuth.new(env)
      end
    end

  end
end

require_relative './v1/routes/snapshots'
require_relative './v1/routes/vendors'

