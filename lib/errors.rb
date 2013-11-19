module Evercam

  class EvercamError < StandardError
  end

  class AuthenticationError < EvercamError
  end

end

require_relative './errors/web'

