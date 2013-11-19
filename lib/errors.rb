module Evercam

  class EvercamError < StandardError
  end

  class NotFoundError < EvercamError
  end

  class ForbiddenError < EvercamError
  end

end
