module Evercam
  module GrapeJSONFormatters

    def self.extended(base)
      base.error_formatter :json, JSONError
      base.formatter :json, JSONObject
    end

    class JSONError
      def self.call(message, backtrace, options, env)
        JSON.pretty_generate({ message: message })
      end
    end

    class JSONObject
      def self.call(object, env=nil)
        JSON.pretty_generate(object) unless object.blank?
      end
    end

  end
end

