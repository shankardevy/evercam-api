module Evercam
  class V1RedirectRoutes < Grape::API
    desc 'Internal endpoint only, keep hidden', {hidden: true}
    get '/cameras/:id/snapshot.jpg' do
      log_redirect(params)
      redirect "/v1/cameras/#{params[:id]}/live/snapshot?#{params.except(:id, :route_info).to_query}"
    end

    desc 'Internal endpoint only, keep hidden', {hidden: true}
    get '/users/:id/cameras' do
      log_redirect(params)
      redirect "/v1/cameras?user_id=#{params[:id]}&#{params.except(:id, :route_info).to_query}"
    end

    desc 'Internal endpoint only, keep hidden', {hidden: true}
    get '/cameras/:id/snapshots/latest' do
      log_redirect(params)
      redirect "/v1/cameras/#{params[:id]}/recordings/snapshots/latest?#{params.except(:id, :route_info).to_query}"
    end

    desc 'Internal endpoint only, keep hidden', {hidden: true}
    get '/shares/cameras/:id' do
      log_redirect(params)
      redirect "/v1/cameras/#{params[:id]}/shares?#{params.except(:id, :route_info).to_query}"
    end

    desc 'Internal endpoint only, keep hidden', {hidden: true}
    get '/shares/requests/:id' do
      log_redirect(params)
      redirect "/v1/cameras/#{params[:id]}/shares/requests?#{params.except(:route_info).to_query}"
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
