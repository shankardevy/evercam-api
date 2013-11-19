module Evercam
  module Formatters

    class JSONError
      def self.call(message, backtrace, options, env)
        JSON.pretty_generate({ message: message })
      end
    end

    class JSONObject
      def self.call(object, env)
        JSON.pretty_generate(object)
      end
    end

  end
end

