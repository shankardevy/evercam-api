module Evercam
  class WebApp

    get '/login' do
      rt = params[:rt]
      redirect rt if rt && session[:user]
      erb 'login'.to_sym
    end

    post '/login' do
      user = User.by_login(params[:username])
      unless user && user.password == params[:password]
        flash.now[:error] = 'Invalid username or email and password combination'
        erb 'login'.to_sym
      else
        rt = params[:rt]
        session[:user] = user.id
        redirect rt ? rt : "/users/#{user.username}"
      end
    end

    get '/logout' do
      session[:user] = nil
      redirect '/login'
    end

    get '/signup' do
      @countries = Country.all
      erb 'signup'.to_sym
    end

    post '/signup' do
      if (outcome = Actors::UserSignup.run(params)).success?
        redirect '/login', success: %(Congratulations, we've sent you a confirmation email to complete the next step in the process)
      else
        redirect '/signup', error: outcome.errors
      end
    end

  end
end

