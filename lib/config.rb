require 'yaml'

module Evercam
  class Config
    class << self

      def database
        ENV['DATABASE_URL'] || settings[env][:database]
      end

      def cookies
        settings[env][:cookies]
      end

      def settings
        @settings ||= (YAML.load(File.read(File.join(
          File.dirname(__FILE__), 'config', 'settings.yaml'))))
      end

      def env
        (ENV['EVERCAM_ENV'] || 'development').to_sym
      end

    end
  end
end

