module Evercam

  class EvercamError < StandardError
  end

  class AuthenticationError < EvercamError
    def initialize(message=nil)
      super(message || "Unauthenticated")
    end
  end

  class AuthorizationError < EvercamError
    def initialize(message=nil)
      super(message || "Unauthorized")
    end
  end

  class NotFoundError < EvercamError
    def initialize(message=nil)
      super(message || "Not Found")
    end
  end

  class CameraOfflineError < EvercamError
    def initialize(message=nil)
      super(message || "Camera Offline")
    end
  end

  class OutcomeError < EvercamError

    def initialize(outcome)
      @outcome = outcome
    end

    def message
      @outcome.errors.message_list.
        map(&:downcase)
    end

  end

end

require_relative './errors/web'

