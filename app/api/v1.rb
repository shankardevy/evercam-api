Dir.glob(File.expand_path('../v1/**/*.rb', __FILE__)).sort.
  each { |f| require f }

module Evercam
  class APIv1 < Grape::API

    # use JSON if accept header empty
    default_format :json

    helpers do
      def auth
        WithAuth.new(env)
      end
      include AuthorizationHelper
      include ErrorsHelper
      include LoggingHelper
      include SessionHelper
      include ThreeScaleHelper
      include ParameterMapper
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

    # bring on the swagger
    add_swagger_documentation(
      Evercam::Config[:swagger][:v1]
    )

    # Dalli cache
    options = { :namespace => "app_v1", :compress => true }
    class << self; attr_accessor :dc end
    @dc = Dalli::Client.new('localhost:11211', options)

    # Uncomment this to see a list of available routes on start up.
    # self.routes.each do |api|
    #   puts "#{api.route_method.ljust(10)} -> /v1#{api.route_path}"
    # end
    #Sequel::Model.db.loggers << Logger.new($stdout)

  end
end

# Disable File validation, it doesn't work
# Add Boolean validation
module Grape
  module Validations
    class CoerceValidator < SingleOptionValidator
      alias_method :validate_param_old!, :validate_param!

      def to_bool(val)
        return true if val == true || val =~ (/(true|t|yes|y|1)$/i)
        return false if val == false || val.blank? || val =~ (/(false|f|no|n|0)$/i)
        nil
      end

      def validate_param!(attr_name, params)
        unless @option.to_s == 'File'
          if @option == 'Boolean'
            params[attr_name] = to_bool(params[attr_name])
            if params[attr_name].nil?
              raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :coerce
            end
          else
            validate_param_old!(attr_name, params)
          end
        end

      end
    end
  end
end
