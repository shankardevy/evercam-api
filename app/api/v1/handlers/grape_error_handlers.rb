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
        status = 500
        details = {"message" => "Sorry, we dropped the ball.",
                   "code" =>    "unknown_error",
                   "context" => []}
        if exception.kind_of?(EvercamError)
          log.error "Evercam error caught processing request.\n"\
                    "Type: #{exception.class.name}\n"\
                    "Message: #{exception.message}\n"\
                    "Code: #{exception.code}\n"\
                    "HTTP Status Code: #{exception.status_code}\n"\
                    "Context: #{exception.context}\nStack Trace:\n" +
                    exception.backtrace[0, 5].join("\n")
          status             = exception.status_code
          if exception.class == OutcomeError
            if JSON.is_json?(exception.message)
              outcome_message = JSON.parse(exception.message)
              outcome_key = outcome_message['errors'].keys.first
              details["message"] = outcome_message["errors"][outcome_key]["message"]
              details["context"] = outcome_message['errors'].keys
              if outcome_key == "email"
                details["code"] = 'duplicate_email_error'
              elsif outcome_key == "country"
                details["code"] = 'country_invalid_error'
              else
                details["code"]  = "unknown_error"
              end
            else
              details["message"] = exception.message.first
              details["code"]    = exception.code
              details["context"] = exception.context
            end
          else
            details["message"] = exception.message
            details["context"] = exception.context
            details["code"]    = exception.code
          end
        elsif exception.kind_of?(Grape::Exceptions::ValidationErrors)
          log.error "Grape validation exception caught processing request.\n"\
                    "Message: #{exception.message}\n" +
                    exception.backtrace[0, 5].join("\n")
          status             = 400
          details["message"] = "Invalid parameters specified for request."
          details["code"]    = "invalid_parameters"
          details["context"] = exception.errors.keys.first
        elsif exception.kind_of?(Sequel::ValidationFailed)
          log.error "Sequel validation exception caught processing request.\n"\
          "Message: #{exception.message}\n" +
          exception.backtrace.join("\n")
          status             = 400
          details["message"] = exception.message
          details["code"]    = "invalid_parameters"
          details["context"] = exception.errors.keys.first
        elsif exception.kind_of?(RuntimeError)
          log.error "Grape RuntimeError caught processing request.\n"\
                    "Message: #{exception.message}\n" +
                      exception.backtrace[0, 5].join("\n")
          status             = 400
          details["message"] = "Invalid parameters specified for request."
          details["code"]    = "invalid_parameters"
          details["context"] = ""
        else
          log.error "Non-Evercam exception caught processing request.\n"\
                    "Type: #{exception.class.name}\n"\
                    "Message: #{exception.message}\n" +
                    exception.backtrace.join("\n")
          status = CLASS_STATUS_MAP[exception.class] if CLASS_STATUS_MAP.include?(exception.class)
          Airbrake.notify_or_ignore(exception, cgi_data: ENV.to_hash)
        end

        log.info "Response:\n#{JSON.pretty_generate(details)}"
        Rack::Response.new(details.to_json, status, "Content-Type" => "application/json").finish
      end
    end
  end
end

