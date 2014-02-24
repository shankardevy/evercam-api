['config', 'models', 'errors', 'actors', 'mailers'].
  each { |f| require_relative "../../lib/#{f}" }

Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).
  each { |f| require f }

module Evercam
  class APIv1 < Grape::API

    $client = ThreeScale::Client.new(:provider_key => 'b25bc9166b8805fc26a96f1130578d2b' )

    # use JSON if accept header empty
    default_format :json

    helpers do
      def auth
        WithAuth.new(env)
      end

      def authreport!(method_name='hits', usage_value=1)
      end
    end

    # disable annoying I18n message
    I18n.enforce_available_locales = false

    # configure the api
    extend GrapeJSONFormatters
    extend GrapeErrorHandlers

    # mount actual endpoints
    mount V1UserRoutes
    mount V1CameraRoutes
    mount V1SnapshotRoutes
    mount V1ModelRoutes

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )

  end
end

