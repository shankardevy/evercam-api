module Evercam
   module ParameterMapper
      TIMEZONE_MAPPINGS = {
         "Asia/Calcutta" => "Asia/Kolkata"
      }

      # This method does parameter manipulation to allow for correction of
      # erroneous inbound values that would otherwise cause issues.
      def map_parameters!
         map_time_zones(params) if params.include?(:timezone)
      end

      # This method fixes issues with unrecognized time zones, mapping them to
      # ones that are recognized.
      def map_time_zones(parameters)
         if TIMEZONE_MAPPINGS.include?(parameters[:timezone])
            log.info "Changing timezone from '#{parameters[:timezone]}' to '#{TIMEZONE_MAPPINGS[parameters[:timezone]]}'."
            parameters[:timezone] = TIMEZONE_MAPPINGS[parameters[:timezone]]
         end
      end
   end
end