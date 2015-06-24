module Evercam
  module Utils
    def self.is_num?(str)
      !!Integer(str)
    rescue ArgumentError, TypeError
      false
    end
  end
end

module JSON
  def self.is_json?(json)
    return false unless json.is_a?(String)
    JSON.parse(json).all?
  rescue JSON::ParserError
    false
  end
end
