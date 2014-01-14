require_relative "./web_router"

module Evercam
  class WebRootRouter < WebRouter

    get '/' do
      erb 'index'.to_sym
    end

    ['about', 'privacy', 'terms', 'jobs', 'media' ,'contact'].each do |url|
      get "/#{url}" do
        erb url.to_sym
      end
    end

    post '/contact' do
      name, email, body = params[:name], params[:email], params[:body]

      unless (name && '' != name) && (email &&  email =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i) && (body && '' != body)
        flash[:error] = 'Sorry but one or more of the form values was empty or invalid. Please try again'
      else
        Intercom::MessageThread.create(email: email, body: body)
        cookies.merge!({ name: name, email: email, created_at: Time.now.to_i })
        flash[:success] = "Thank you for your interest. We'll be in contact soon..."
      end

      redirect '/contact'
    end

  end
end

