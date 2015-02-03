module Evercam
  class V1RedirectRoutes < Grape::API

    get '/cameras/:id/snapshot.jpg' do
      log_redirect(params)
      redirect "/v1/cameras/#{params[:id]}/live/snapshot?#{params.except(:id, :route_info).to_query}"
    end
  end
end

def log_redirect(params)
  user = User.where(api_id: params[:api_id]).first
  client = Client.where(api_id: params[:api_id]).first
  log.warn "Old Endpoint Requested: '#{params[:route_info]}'"
  if params[:api_id]
    unless user.blank?
      log.warn "Requester is an User. It's username is '#{user.username}' and email is '#{user.email}'."
    end
    unless client.blank?
      log.warn "Requester is an API client. It's name is '#{client.name}'."
    end
  else
    log.warn "Requester is anonymous."
  end
  log.warn "Request Parameters: #{params.to_hash.except(:route_info).inspect}"
end
