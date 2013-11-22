module Evercam
  class WebApp

    get '/jobs' do
      erb 'jobs'.to_sym
    end

  end
end

