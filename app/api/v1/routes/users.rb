module Evercam
  class APIv1

    post '/users' do
      outcome = Actors::UserSignup.run(params)
      user = outcome.result

      {
        users: [{
          id: user.username,
          forename: user.forename,
          lastname: user.lastname,
          username: user.username,
          email: user.email,
          country: user.country.iso3166_a2,
          created_at: user.created_at.to_i,
          updated_at: user.updated_at.to_i,
          confirmed_at: nil
        }]
      }
    end

  end
end

