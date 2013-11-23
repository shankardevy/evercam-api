module Evercam
  class WebApp

    set :api, File.join(settings.root, '..', 'api')

    get '/docs/:version/:route' do |version, route|
      path = File.join(settings.api, version, 'routes')

      file = File.join(path, "#{route}.erb")
      raise NotFoundError unless File.exists?(file)

      erb route.to_sym, views: path
    end

  end
end

