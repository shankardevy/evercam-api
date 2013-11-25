module Evercam
  class WebApp

    get '/' do
      erb 'index'.to_sym
    end

    ['about', 'privacy', 'terms', 'jobs'].each do |url|
      get "/#{url}" do
        erb url.to_sym
      end
    end

  end
end

