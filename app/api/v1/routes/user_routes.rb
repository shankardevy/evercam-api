require_relative '../presenters/user_presenter'
require_relative '../presenters/stream_presenter'

module Evercam
  class V1UserRoutes < Grape::API

    post '/users' do
      outcome = Actors::UserSignup.run(params)
      raise OutcomeError, outcome unless outcome.success?

      user = outcome.result
      present Array(user), with: UserPresenter
    end

    get '/users/:username/streams' do
      user = ::User.by_login(params[:username])
      raise NotFoundError, 'user does not exist' unless user

      streams = user.streams.select do |s|
        s.is_public || (auth.user && s.has_right?('view', auth.user))
      end

      present streams, with: StreamPresenter
    end

  end
end

