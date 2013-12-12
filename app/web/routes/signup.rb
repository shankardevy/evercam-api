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

  end
end

