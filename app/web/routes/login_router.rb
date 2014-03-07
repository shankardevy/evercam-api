require_relative "./web_router"

module Evercam
  class WebLoginRouter < WebRouter

    get '/login' do
      rt = params[:rt]

      if curr_user
        redirect rt ? rt : "/users/#{curr_user.username}"
      end

      erb 'login'.to_sym
    end

    post '/login' do
      user = User.by_login(params[:username])

      unless user && user.password == params[:password]
        session[:user] = nil
        redirect request.referrer || '/login', error:
          'Invalid username or email and password combination'
      else
        session[:user] = user.id
        cookies.merge!({ name: user.fullname, email: user.email, created_at: user.created_at.to_i })

        # Check for 3scale account and create it if needed
        if user.api_id.nil? or user.api_key.nil?
          begin
            threescale_user_id(user.username)
          rescue BadRequestError
            # No 3scale account, create one
            threescale_signup(user, params[:password])
          end
        end
        redirect params[:rt] ? params[:rt] : "/users/#{user.username}"
      end
    end

    get '/logout' do
      session[:user] = nil
      redirect '/login'
    end

  end
end

