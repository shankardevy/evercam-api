require_relative '../presenters/user_presenter'
require_relative '../presenters/stream_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    include WebErrors

    desc 'Starts the new user signup process', {
      entity: Evercam::Presenters::User
    }
    post '/users' do
      outcome = Actors::UserSignup.run(params)
      raise OutcomeError, outcome unless outcome.success?

      user = outcome.result
      present Array(user), with: Presenters::User
    end

    desc 'Returns the set of streams owned by a particular user', {
      entity: Evercam::Presenters::Stream
    }
    get '/users/:username/streams' do
      user = ::User.by_login(params[:username])
      raise NotFoundError, 'user does not exist' unless user

      streams = user.streams.select do |s|
        s.is_public || (auth.user && s.has_right?('view', auth.user))
      end

      present streams, with: Presenters::Stream
    end

  end
end

