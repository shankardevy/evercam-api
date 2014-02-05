require_relative "./web_router"

module Evercam
  class WebAccountRouter < WebRouter

    get '/reset/password' do
      erb 'account/reset'.to_sym
    end

    post '/reset/password' do

      email = params[:email]

      uri = URI.parse(request.url)

      unless email =~ /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i
        flash[:error] = 'Sorry but the email address you entered does not appear to be valid'

        redirect '/reset/password'
      else

        user = User.by_login(params[:email])
        token = SecureRandom.hex(16)

        if user
          t = Time.now
          expires = t + 1.hour

          User.by_login(user.username).update(reset_token: token, token_expires_at: expires)

          Mailers::AccountMailer.password_reset(user: user, token: token, uri: uri, request: request)
          cookies.merge!({ email: email, created_at: Time.now.to_i })
        end

        flash[:success] = "Please check your email for further instructions..."
      end

      redirect '/login'
    end

    get '/reset/confirm' do
      @user = confirm_validate
      erb 'account/confirm_password_reset'.to_sym
    end

    post '/reset/confirm' do
      @user = confirm_validate

      outcome = Actors::PasswordReset.run(params.merge(username: @user.username, password: params[:password], confirmation: params[:confirmation]))

      if outcome.success?
        session[:user] = @user.pk

        # reusing the UserConfirm actor as functionality is basically the same
        Actors::UserConfirm.run(username: @user.username, confirmation: params[:confirmation])

        User.by_login(@user.username).update(reset_token: '', token_expires_at: Time.now)

        redirect "/users/#{@user.username}", info: 'Your account has now been reset'
      else
        flash[:error] = outcome.errors

        redirect '/login'
      end

      flash.now[:error] = outcome.errors  
      erb 'confirm'.to_sym
    end

    private

    def confirm_validate           
      User.by_login(params[:u]).tap do |user|
        t = Time.now

        unless user && user.reset_token == params[:t] && t <= user.token_expires_at
          redirect '/reset/password', error: "Sorry, but we could not complete your password reset request, please try again!"
        end
      end
    end

  end
end

