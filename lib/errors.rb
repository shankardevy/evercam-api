module Evercam

  class EvercamError < StandardError
  end

  class AuthenticationError < EvercamError
  end

  class AuthorizationError < EvercamError
  end

end

require_relative './errors/web'

