require_relative '../presenters/stream_presenter'

module Evercam
  class V1StreamRoutes < Grape::API

    include WebErrors

    desc 'Returns all data for a given stream', {
      entity: Evercam::Presenters::Stream
    }
    get '/streams/:name' do
      stream = ::Stream.by_name(params[:name])
      raise NotFoundError, 'stream was not found' unless stream

      unless stream.is_public? || auth.has_right?('view', stream)
        raise AuthorizationError, 'not authorized to view this stream'
      end

      present Array(stream), with: Presenters::Stream
    end

    desc 'Creates a new stream owned by the authenticating user', {
      entity: Evercam::Presenters::Stream
    }
    post '/streams' do
      inputs = params.merge(username: auth.user!.username)

      outcome = Actors::StreamCreate.run(inputs)
      raise OutcomeError, outcome unless outcome.success?
      stream = outcome.result

      present Array(stream), with: Presenters::Stream
    end

  end
end

