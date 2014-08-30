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

    get '/webhooks' do
      # I can't find cleaner way to do it with current grape version
      params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
      params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')

      camera = get_cam(params[:id])

      webhooks = Webhook.where(camera_id: camera[:id], user_id: caller[:id]).all

      present webhooks, with: Presenters::Webhook
    end

    desc 'Returns a specific webhook'
    params do
      requires :id, type: String, desc: "Unique identifier for the webhook"
    end

    get '/webhooks/:id' do
      # I can't find cleaner way to do it with current grape version
      params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
      params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')

      webhook = Webhook[params[:id]]

      if webhook.nil?
        raise Evercam::NotFoundError.new("Unable to locate the webhook with the id of '#{params[:id]}'.",
                                         "webhook_not_found_error", params[:id])
      end

      present webhook, with: Presenters::Webhook
    end

    desc 'Create a new webhook', {
      entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :user_id, type: String, desc: "Unique identifier for the user"
      requires :url, type: String, desc: "Webhook URL."
    end

    post '/webhooks' do

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
      requires :id, type: Integer, desc: "Unique identifier for the webhook"
      requires :url, type: String, desc: "Webhook URL."
    end

    patch '/webhooks/:id' do

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
      requires :id, type: Integer, desc: "Unique identifier for the webhook"
    end

    delete '/webhooks/:id' do

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

