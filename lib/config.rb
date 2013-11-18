require 'yaml'

module Evercam
  class Config
    class << self

      def [](key)
        settings[env][key]
      end

      def settings
        @settings ||= (YAML.load(
          ERB.new(File.read(File.join(
            File.dirname(__FILE__), 'config', 'settings.yaml'))).
          result))
      end

      def env
        (ENV['EVERCAM_ENV'] || 'development').to_sym
      end

    end
  end
end

