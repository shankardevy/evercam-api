['config',
 'errors',
 'models',
 'actors',
 'mailers'
].each { |f| require_relative "../../lib/#{f}" }

['formatters/json',
 'helpers/with_auth',
 'routes/stream_routes'
].each { |f| require_relative "./v1/#{f}" }

module Evercam
  class APIv1 < Grape::API

    include WebErrors

    # ensure cookies work across subdomains
    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    # use JSON if accept header empty
    default_format :json

    # configure custom JSON formatters
    error_formatter :json, Formatters::JSONError
    formatter :json, Formatters::JSONObject

    # errors where the user has made a mistake
    rescue_from BadRequestError, OutcomeError do |e|
      error_response({ status: 400, message: e.message })
    end

    # errors where user has failed to provide authentication
    rescue_from AuthenticationError do |e|
      error_response({ status: 401, message: e.message })
    end

    # errors where user does not have sufficient rights
    rescue_from AuthorizationError do |e|
      error_response({ status: 403, message: e.message })
    end

    # errors where something does not exist
    rescue_from NotFoundError do |e|
      error_response({ status: 404, message: e.message })
    end

    # woops, we broke something, go crazy...
    rescue_from :all do |e|
      Grape::API.logger.error e
      error_response({ status: 500, message: 'Sorry, we dropped the ball' })
    end

    helpers do

      def auth
        WithAuth.new(env)
      end

    end

    mount V1StreamRoutes

  end
end

['routes/models',
 'presenters/vendor_presenter',
 'presenters/model_presenter',
 'presenters/stream_presenter',
 'routes/users'
].each { |f| require_relative "./v1/#{f}" }

