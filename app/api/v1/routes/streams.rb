module Evercam
  class APIv1

    get '/streams/:name' do
      stream = ::Stream.by_name(params[:name])
      raise NotFoundError, 'stream was not found' unless stream

      unless stream.is_public? || auth.has_right?('view', stream)
        raise AuthorizationError, 'not authorized to view this stream'
      end

      StreamPresenter.export(stream)
    end

    post '/streams' do
      inputs = params.merge(username: auth.user!.username)

      outcome = Actors::StreamCreate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?

      StreamPresenter.export(outcome.result)
    end

  end
end

