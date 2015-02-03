require_relative '../presenters/webhook_presenter'

module Evercam
  class V1WebhookRoutes < Grape::API

    include WebErrors

    DEFAULT_LIMIT = 50

    before do
      authorize!
    end

    #-------------------------------------------------------------------------
    # GET /v1/cameras/:id/webhooks
    #-------------------------------------------------------------------------
    desc 'Returns list of webhooks for a given camera'
    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      optional :webhook_id, type: String, desc: "Unique identifier for the webhook"
    end

    get '/cameras/:id/webhooks' do
      # I can't find cleaner way to do it with current grape version
      params[:id] = params[:id][0..-6] if params[:id].end_with?('.json')
      params[:id] = params[:id][0..-5] if params[:id].end_with?('.xml')

      camera = get_cam(params[:id])

      if params.include?(:webhook_id) && params[:webhook_id]
        webhooks = Webhook.where(exid: params[:webhook_id]).all
      else
        webhooks = Webhook.where(camera: camera, user_id: caller[:id]).all
      end

      present webhooks, with: Presenters::Webhook
    end

    #-------------------------------------------------------------------------
    # POST /v1/cameras/:id/webhooks
    #-------------------------------------------------------------------------
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


    #-------------------------------------------------------------------------
    # PATCH /v1/cameras/:id/webhooks/:webhook_id
    #-------------------------------------------------------------------------
    desc 'Updates webhook URL', {
        entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :webhook_id, type: String, desc: "Unique identifier for the webhook"
      requires :url, type: String, desc: "Webhook URL."
    end

    patch '/cameras/:id/webhooks/:webhook_id' do
      outcome = Actors::WebhookUpdate.run(params.merge!(:caller_id => caller[:id]))
      unless outcome.success?
        raise_error(400, "invalid_parameters",
                    "Invalid parameters specified to request.",
                    *(outcome.errors.keys))
      end

      present Array(outcome.result), with: Presenters::Webhook
    end

    #-------------------------------------------------------------------------
    # DELETE /v1/cameras/:id/webhooks/:webhook_id
    #-------------------------------------------------------------------------
    desc 'Deletes specified webhook', {
        entity: Evercam::Presenters::Webhook
    }

    params do
      requires :id, type: String, desc: "Unique identifier for the camera"
      requires :webhook_id, type: String, desc: "Unique identifier for the webhook"
    end

    delete '/cameras/:id/webhooks/:webhook_id' do

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
