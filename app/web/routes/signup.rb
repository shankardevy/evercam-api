module Evercam
  class WebApp

    get '/signup' do
      @countries = Country.all
      erb 'signup'.to_sym
    end

    post '/signup' do
      if (outcome = Actors::UserSignup.run(params)).success?
        redirect '/login', success:
          %(Congratulations, we've sent you a confirmation email to complete the next step in the process)
      else
        redirect '/signup', error:
          outcome.errors
      end
    end

    get '/confirm' do
      @user = User.by_login(params[:u])

      if @user && @user.confirmed?
        redirect '/login', info: 'This account has already been confirmed, you can now login'
      end

      unless @user && @user.password == params[:c]
        redirect '/signup', error: 'Sorry but these credentials do not appear to be valid'
      end

      erb 'confirm'.to_sym
    end

    post '/interested' do
      email = params[:email]

      unless email =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
        flash[:error] = 'Sorry but the email address you entered does not appear to be valid'
      else
        Mailers::UserMailer.interested(email: email, request: request)
        cookies.merge!({ email: email, created_at: Time.now.to_i })
        flash[:success] = "Thank you for your interest. We'll be in contact soon..."
      end

      redirect '/'
    end

  end
end

