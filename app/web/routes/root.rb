module Evercam
  class WebApp

    get '/' do
      erb 'index'.to_sym
    end

    ['about', 'privacy', 'terms', 'jobs',
     'marketplace', 'media'].each do |url|
      get "/#{url}" do
        erb url.to_sym
      end
    end

    post '/interested' do
      email = params[:email]

      unless email =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
        flash[:error] = 'Sorry but the email address you entered does not appear to be valid'
      else
        cookies.merge!({ email: email, created_at: Time.now.to_i })
        Mailers::UserMailer.interested(email: email, request: request)
        flash[:success] = "Thank you for your interest. We'll be in contact soon..."
      end

      redirect '/'
    end

  end
end

