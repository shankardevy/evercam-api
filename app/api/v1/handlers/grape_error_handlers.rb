module Evercam
  module GrapeErrorHandlers

    include WebErrors

    def self.extended(base)

      # errors where the user has made a mistake
      base.rescue_from BadRequestError, OutcomeError,
        Grape::Exceptions::ValidationErrors do |e|
        error_response({ status: 400, message: e.message })
      end

      # errors where user has failed to provide authentication
      base.rescue_from AuthenticationError do |e|
        error_response({ status: 401, message: e.message })
      end

      # errors where user does not have sufficient rights
      base.rescue_from AuthorizationError do |e|
        error_response({ status: 403, message: e.message })
      end

      # errors where something does not exist
      base.rescue_from NotFoundError do |e|
        error_response({ status: 404, message: e.message })
      end

      # errors where a conflict exists
      base.rescue_from ConflictError do |e|
        error_response({ status: 409, message: e.message })
      end

      # errors where camera is offline
      base.rescue_from CameraOfflineError do |e|
        error_response({ status: 503, message: e.message })
      end

      # errors where the endpoint is not implemented yet
      base.rescue_from ComingSoonError do |e|
        error_response({ status: 501, message: 'Sorry, this method is not implemented yet' })
      end

      # woops, we broke something, go crazy...
      base.rescue_from :all do |e|
        Grape::API.logger.error e
        error_response({ status: 500, message: 'Sorry, we dropped the ball' })
      end

    end

  end
end

