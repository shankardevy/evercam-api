module Evercam
  module FormHelpers

    def input(name, type, required, opts={})
      attrs = defaults(name, required).merge({ type: type }).merge(opts)

      if input_value(name) && :password != type
        attrs = attrs.merge(value: input_value(name))
      end

      %(<input #{render_attrs(attrs)}>)
    end

    def select(name, values, required, opts={})
      attrs = defaults(name, required).merge(opts)

      items = render_options(name, values)
      items.unshift(%(<option>Please Select</option>))

      %(<select #{render_attrs(attrs)}>#{items.join}</select>)
    end

    def render_options(name, values)
      values.map do |opt|
        if input_value(name) == opt[0]
          %(<option value="#{opt[0]}" selected>#{opt[1]}</option>)
        else
          %(<option value="#{opt[0]}">#{opt[1]}</option>)
        end
      end
    end

    def render_attrs(attrs)
      attrs.map { |k,v| %(#{k}="#{v}") }.join(' ')
    end

    def defaults(name, required)
      attrs = { name: name }

      if input_error(name)
        attrs = attrs.merge({ 'data-error' => input_error(name), class: 'form-control has-error' })
      elsif :required == required
        attrs = attrs.merge({ 'data-notice' => 'Required', class: 'form-control is-required' })
      elsif :optional == required
        attrs = attrs.merge({ 'data-notice' => 'Optional', class: 'form-control is-optional' })
      end

      attrs
    end

    def input_value(name)
      return params[name] if params[name] &&
        !params[name].empty?
    end

    def input_error(name)
      errors = flash[:error]
      return unless errors &&
        Hash === errors &&
        errors.keys.map(&:to_sym).
        include?(name.to_sym)

      err = errors[name.to_sym] || errors[name.to_s]
      err.message
    end

  end
end

