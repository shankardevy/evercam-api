module Evercam
  class WebApp

    get '/about' do
      erb 'about'.to_sym
    end

    get '/privacy' do
      erb 'privacy'.to_sym
    end

    get '/jobs' do
      erb 'jobs'.to_sym
    end

  end
end

