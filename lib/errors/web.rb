module Evercam
  module WebErrors

    class BadRequestError < EvercamError
      def initialize(message=nil)
        super(message || "Bad Request")
      end
    end

    class ComingSoonError < EvercamError
      def initialize(message=nil)
        super(message || "Coming Soon")
      end
    end

    class ConflictError < EvercamError
      def initialize(message=nil)
        super(message || "Conflict")
      end
    end

  end
end

