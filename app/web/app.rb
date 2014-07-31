require_relative 'routes/root_router'

module Evercam
  class WebApp < Sinatra::Base

    use Evercam::WebRootRouter
   
  end
end

