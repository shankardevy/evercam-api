# Disable File validation, it doesn't work
# Add Boolean validation
module Grape
  module Validations
    class CoerceValidator < SingleOptionValidator
      alias_method :validate_param_old!, :validate_param!

      def to_bool(val)
        return true if val == true || val =~ (/(true|t|yes|y|1)$/i)
        return false if val == false || val.blank? || val =~ (/(false|f|no|n|0)$/i)
        nil
      end

      def validate_param!(attr_name, params)
        unless @option.to_s == 'File' or @option.to_s == 'Float'
          if @option == 'Boolean'
            params[attr_name] = to_bool(params[attr_name])
            if params[attr_name].nil?
              raise Grape::Exceptions::Validation, param: @scope.full_name(attr_name), message_key: :coerce
            end
          else
            validate_param_old!(attr_name, params)
          end
        end

      end
    end
  end
end
