['config',
 'errors',
 'models',
 'actors',
 'mailers'
].each { |f| require_relative "../../lib/#{f}" }

['helpers/form_helpers',
 'helpers/template_helpers',
 'routes/oauth2_router'
].each { |f| require_relative "./#{f}" }


module Evercam
  class WebApp < Sinatra::Base

    use Evercam::WebOAuth2Router
   
  end
end

