module Evercam
  module GrapeErrorHandlers

    include WebErrors

    EXCEPTION_CLASSES = [
        AuthorizationError,
        AuthenticationError,
        BadRequestError,
        CameraOfflineError,
        ComingSoonError,
        ConflictError,
        Grape::Exceptions::ValidationErrors,
        OutcomeError,
        NotFoundError]

    CLASS_STATUS_MAP = {
      AuthorizationError                  => 403,
      AuthenticationError                 => 401,
      BadRequestError                     => 400,
      CameraOfflineError                  => 503,
      ComingSoonError                     => 501,
      ConflictError                       => 409,
      Grape::Exceptions::ValidationErrors => 400,
      OutcomeError                        => 400,
      NotFoundError                       => 404
    }

    def self.extended(base)
      base.rescue_from :all do |exception|
        log.error "Exception caught processing request.\nType: "\
                  "#{exception.class.name}\nMessage: #{exception.message}\n" +
                  exception.backtrace.join("\n")
        Airbrake.notify_or_ignore(exception, cgi_data: ENV.to_hash)
        code    = (CLASS_STATUS_MAP[exception.class] || 500)
        message = "Sorry, we dropped the ball."
        if exception.kind_of?(ComingSoonError)
          message = "Sorry, this method is not implemented yet."
        elsif EXCEPTION_CLASSES.include?(exception.class)
          message = exception.message
        end
        log.info "HTTP Return Status: #{code}, Message: '#{message}'"
        Airbrake.notify_or_ignore(exception, cgi_data: ENV.to_hash)
        error_response(status: code, message: message)
      end
    end
  end
end

