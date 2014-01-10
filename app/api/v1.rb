['config', 'models', 'errors', 'actors', 'mailers'].
  each { |f| require_relative "../../lib/#{f}" }

Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).
  each { |f| require f }

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

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )

  end
end

