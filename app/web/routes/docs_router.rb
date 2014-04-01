require_relative "./web_router"

module Evercam
  class WebDocsRouter < WebRouter

    get '/docs' do
      erb 'docs/index'.to_sym, layout: 'layouts/docs'.to_sym
    end

    get '/docs/*' do
      begin
        file = params[:splat][0]
        path = File.join('docs', file)
        erb path.to_sym, layout: 'layouts/docs'.to_sym
      rescue Exception => e
        raise NotFoundError
      end
    end

  end
end

