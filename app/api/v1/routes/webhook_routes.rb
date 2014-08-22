require_relative '../presenters/webhook_presenter'

module Evercam
  class V1WebhookRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 50

    before do
      authorize!
    end

    desc 'Returns list of webhooks for given camera'
    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
    end

    get '/cameras/:id/webhooks' do
      camera = get_cam(params[:id])

      webhooks = Webhook.where(camera_id: camera[:id], user_id: caller[:id]).all

      present webhooks, with: Presenters::Webhook
    end

    desc 'Create a new webhook', {
      entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :user_id, type: String, desc: "Unique identifier for the user"
      requires :url, type: String, desc: "Webhook URL."
    end

    post '/cameras/:id/webhooks' do

      outcome = Actors::WebhookCreate.run(params.merge!(:caller_id => caller[:id]))

      unless outcome.success?
        raise_error(400, "invalid_parameters",
                    "Invalid parameters specified to request.",
                    *(outcome.errors.keys))
      end

      present Array(outcome.result), with: Presenters::Webhook
    end

    desc 'Updates webhook URL', {
      entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :webhook_id, type: Integer, desc: "Unique identifier for the webhook"
      requires :url, type: String, desc: "Webhook URL."
    end

    patch '/cameras/:id/webhooks' do

      outcome = Actors::WebhookUpdate.run(params.merge!(:caller_id => caller[:id]))
      unless outcome.success?
        raise_error(400, "invalid_parameters",
                    "Invalid parameters specified to request.",
                    *(outcome.errors.keys))
      end

      present Array(outcome.result), with: Presenters::Webhook
    end

    desc 'Deletes specified webhook', {
      entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :webhook_id, type: Integer, desc: "Unique identifier for the webhook"
    end

    delete '/cameras/:id/webhooks' do

      outcome = Actors::WebhookDelete.run(params.merge!(:caller_id => caller[:id]))
      unless outcome.success?
        raise_error(400, "invalid_parameters",
                    "Invalid parameters specified to request.",
                    *(outcome.errors.keys))
      end

      present Array(outcome.result), with: Presenters::Webhook
    end

  end
end

