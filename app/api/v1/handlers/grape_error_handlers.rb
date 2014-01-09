require_relative '../../../../lib/errors'

module Evercam
  module GrapeErrorHandlers

    include WebErrors

    def self.extended(base)

      # errors where the user has made a mistake
      base.rescue_from BadRequestError, OutcomeError do |e|
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

      # woops, we broke something, go crazy...
      base.rescue_from :all do |e|
        Grape::API.logger.error e
        error_response({ status: 500, message: 'Sorry, we dropped the ball' })
      end

    end

  end
end

