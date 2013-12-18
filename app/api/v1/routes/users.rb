module Evercam
  class APIv1

    post '/users' do
      outcome = Actors::UserSignup.run(params)
      raise OutcomeError, outcome unless outcome.success?
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

    get '/users/:username/streams' do
      user = ::User.by_login(params[:username])
      raise NotFoundError, 'user does not exist' unless user

      streams = user.streams.select do |s|
        s.is_public || (auth.user && s.has_right?('view', auth.user))
      end

      StreamPresenter.export(streams)
    end

  end
end

