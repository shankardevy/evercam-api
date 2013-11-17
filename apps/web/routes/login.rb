module Evercam
  class WebApp

    get '/login' do
      rt = params[:rt]
      redirect rt if rt && session[:user]
      erb :login
    end

    get '/logout' do
      session[:user] = nil
      redirect '/login'
    end

  end
end

