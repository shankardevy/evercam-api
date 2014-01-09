['config', 'models', 'actors', 'mailers'
].each { |f| require_relative "../../lib/#{f}" }

['helpers/with_auth',
 'formatters/grape_json_formatters',
 'handlers/grape_error_handlers',
 'routes/user_routes',
 'routes/stream_routes',
 'routes/model_routes'
].each { |f| require_relative "./v1/#{f}" }

module Evercam
  class APIv1 < Grape::API

    # use JSON if accept header empty
    default_format :json

    # ensure cookies work across subdomains
    use Rack::Session::Cookie,
      Evercam::Config[:cookies]

    helpers do
      def auth
        WithAuth.new(env)
      end
    end

    # configure the api
    extend GrapeJSONFormatters
    extend GrapeErrorHandlers

    # mount actual endpoints
    mount V1UserRoutes
    mount V1StreamRoutes
    mount V1ModelRoutes

  end
end

