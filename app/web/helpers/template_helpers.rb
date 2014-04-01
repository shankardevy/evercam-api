module Evercam
  module TemplateHelpers

    def code(n)
      txt = Rack::Utils::HTTP_STATUS_CODES[n]
      css = (200..299).include?(n) ? 'success' : 'danger'
      "<span class='status label label-#{css}'>#{n} #{txt}</span>"
    end

  end
end

