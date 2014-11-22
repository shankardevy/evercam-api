Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).sort.
  each { |f| require f }

require_relative '../../lib/actors'
require_relative '../../lib/services'

module Evercam
  class APIv1 < Grape::API

	formatter :m3u8, lambda { |object, env| object }

	content_type :json, "application/json"

    # use JSON if accept header empty
    default_format :json

    helpers do
      def auth
        WithAuth.new(env)
      end
      include AuthorizationHelper
      include CameraHelper
      include CacheHelper
      include ErrorsHelper
      include LoggingHelper
      include SessionHelper
      include ThreeScaleHelper
      include ParameterMapper
      include Services
    end

    # The position of this is important so beware of moving it!
    before do
      map_parameters!
    end

    # disable annoying I18n message
    I18n.enforce_available_locales = false

    # configure the api
    extend GrapeJSONFormatters
    extend GrapeErrorHandlers

    # Mount actual endpoints
    mount V1UserRoutes
    mount V1CameraRoutes
    mount V1SnapshotRoutes
    mount V1SnapshotJpgRoutes
    mount V1ModelRoutes
    mount V1TestRoutes
    mount V1ClientRoutes
    mount V1PublicRoutes
    mount V1ShareRoutes
    mount V1LogRoutes
    mount V1WebhookRoutes

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )
    
    # Uncomment this to see a list of available routes on start up.
    # self.routes.each do |api|
    #   puts "#{api.route_method.ljust(10)} -> /v1#{api.route_path}"
    # end
    #Sequel::Model.db.loggers << Logger.new($stdout)

  end
end
