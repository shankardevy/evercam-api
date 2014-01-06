
module Evercam
  class WebApp

    get '/marketplace' do
      erb 'marketplace/index'.to_sym
    end

  end
end
