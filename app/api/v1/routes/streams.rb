module Evercam
  class APIv1

    post '/streams' do
      inputs = params.merge(username: auth.user!.username)

      outcome = Actors::StreamCreate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?

      StreamPresenter.export(outcome.result)
    end

  end
end

