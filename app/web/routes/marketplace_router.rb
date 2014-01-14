require_relative "./web_router"

module Evercam
  class WebMarketPlaceRouter < WebRouter

    get '/marketplace' do
      erb 'marketplace/index'.to_sym
    end

    post '/marketplace/idea' do
      email, idea = params[:email], params[:idea]

      unless email =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i && idea && '' != idea.strip
        flash[:error] = 'Sorry but the email address or idea you entered does not appear to be valid'
      else
        Mailers::UserMailer.app_idea(email: email, idea: idea, request: request)
        cookies.merge!({ email: email, created_at: Time.now.to_i })
        flash[:success] = "Thank you for your idea. We'll be in contact soon..."
      end

      redirect '/marketplace'
    end

  end
end
