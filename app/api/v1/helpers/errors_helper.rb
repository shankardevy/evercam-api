module Evercam
   module ErrorsHelper
      # This method raises an error constructed from the details passed in the
      # call.
      #
      # ==== Parameters
      # type::      Either an error code (one of the standard HTTP status codes)
      #             or an Exception class. If a code is specified then it will
      #             be used to determine the type of exception raised, which
      #             defaults to an EvercamError for cases where an explicit
      #             exception class does not exist.
      # code::      The error code associated with the exception being raised.
      #             This should be a string describing the error condition that
      #             has occurred. Stick to all lower case with words separated
      #             by underscores.
      # message::   A string containing the message to be set on the exception.
      #             Defaults to nil.
      # *context::  All remaining parameters will be added as context values to
      #             the exception raised.
      def raise_error(type, code, message=nil, *context)
         if type.kind_of?(Integer)
            error_class = nil
            case type
               when 400
                  error_class = Evercam::BadRequestError
               when 401
                  error_class = Evercam::AuthenticationError
               when 403
                  error_class = Evercam::AuthorizationError
               when 404
                  error_class = Evercam::NotFoundError
               when 409
                  error_class = Evercam::ConflictError
               else
                  error_class = Evercam::EvercamError
            end
            raise error_class.new(message, code, *context)
         elsif type < EvercamError
            raise type.new(message, 400, code, *context)
         else
            raise type.new(message)
         end
      end
   end
end

module JSON
  def self.is_json?(json)
    begin
      return false unless json.is_a?(String)
      JSON.parse(json).all?
    rescue JSON::ParserError
      false
    end
  end
end
