require 'logjam'
require 'pony'

module Evercam
  module Mailers
    class Mailer
      LogJam.apply(self, "actors")

      @@templates = {}

      def initialize(inputs)
        @inputs = inputs
      end

      def erb(name)
        ERB.new(template(name)).result(binding)
      end

      private

      def template(name)
        @@templates[name] ||= File.read(
          File.expand_path(File.join('.', name))
        )
      end

      def method_missing(name)
        if @inputs.keys.include?(name)
          @inputs[name]
        end
      end

      def self.method_missing(name, *inputs)
        if self.method_defined?(name) && inputs[0]
          begin
            opts = self.new(inputs[0]).send(name)
            mail = Evercam::Config[:mail].merge(opts)
            Pony.mail(mail)
          rescue Exception => e
            log.warn(e)
          end
        end
      end

    end
  end
end

