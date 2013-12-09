module Evercam

  class EvercamError < StandardError
  end

  class AuthenticationError < EvercamError
  end

  class AuthorizationError < EvercamError
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

