module Evercam
  class WebApp

    get '/docs/*' do
      begin
        file = params[:splat][0]
        path = File.join('docs', file)
        erb path.to_sym, layout: 'layouts/docs'.to_sym
      rescue
        raise NotFoundError
      end
    end

  end
end

