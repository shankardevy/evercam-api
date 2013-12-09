require_relative './v1/formatters/json'
require_relative './v1/helpers/with_auth'

require_relative '../../lib/actors'
require_relative '../../lib/mailers'

module Evercam
  class APIv1 < Grape::API

    include WebErrors

    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    default_format :json

    error_formatter :json, Formatters::JSONError
    formatter :json, Formatters::JSONObject

    rescue_from BadRequestError, OutcomeError do |e|
      error_response({ status: 400, message: e.message })
    end

    rescue_from AuthenticationError do |e|
      error_response({ status: 401, message: e.message })
    end

    rescue_from AuthorizationError do |e|
      error_response({ status: 403, message: e.message })
    end

    rescue_from NotFoundError do |e|
      error_response({ status: 404, message: e.message })
    end

    rescue_from :all do |e|
      error_response({ status: 500, message: 'Sorry, we dropped the ball' })
    end

    helpers do
      def auth
        WithAuth.new(env)
      end
    end

  end
end

require_relative './v1/routes/snapshots'

require_relative './v1/presenters/vendor_presenter'
require_relative './v1/routes/vendors'

require_relative './v1/routes/users'

