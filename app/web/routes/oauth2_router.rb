require_relative "./web_router"
require '3scale_client'
require 'securerandom'

module Evercam
  class WebOAuth2Router < WebRouter

    get '/oauth2/error' do
    end

    get '/oauth2/authorize' do
      begin
        raise BadRequestError if [nil, ''].include?(params[:client_id])
        raise BadRequestError if [nil, ''].include?(params[:redirect_uri])
        raise BadRequestError if params[:response_type] != 'code'
        raise BadRequestError if [nil, ''].include?(params[:scope])

        if Client.where(exid: params[:client_id]).count == 0
          Client.create(exid: params[:client_id])
        end

        with_user do |user|
          @req = OAuth2::Authorize.new(user, params)

          redirect @req.redirect_to if @req.redirect?
          raise BadRequestError, @req.error unless @req.valid?

          @client_id    = params[:client_id]
          @redirect_uri = params[:redirect_uri]
          @scope        = params[:scope]
          erb 'oauth2/authorize'.to_sym
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
    end

    post '/oauth2/authorize' do
      begin
        with_user do |user|
          params[:response_type] = 'code'
          @req = OAuth2::Authorize.new(user, params)

          redirect @req.redirect_to if @req.redirect?
          raise BadRequestError, @req.error unless @req.valid?

          case params[:action]
            when /approve/i
              @req.approve!
            else
              @req.decline! 
          end

          redirect @req.redirect_to
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
    end

    post '/oauth2/token' do
      begin
        raise BadRequestError if [nil, ''].include?(params[:code])
        raise BadRequestError if [nil, ''].include?(params[:client_id])
        raise BadRequestError if [nil, ''].include?(params[:client_secret])
        raise BadRequestError if [nil, ''].include?(params[:redirect_uri])
        raise BadRequestError if params[:grant_type] != "authorization_code"

        client = Client.where(exid: params[:client_id]).first
        raise BadRequestError if client.nil?

        three_scale = ::ThreeScale::Client.new(:provider_key => Evercam::Config[:threescale][:provider_key])
        response    = three_scale.authrep(app_id: params[:client_id],
                                          app_key: params[:client_secret])
        raise BadRequestError if !response.success?

        redirect_uri = params[:redirect_uri]

        access_token = AccessToken.where(client_id: client.id,
                                         refresh:   params[:code]).first
        raise BadRequestError if access_token.nil?
        raise BadRequestError if access_token.is_revoked?

        if access_token.is_expired?
          # Issue new access token.
          access_token = AccessToken.create(client: client_id)
        else
          # Change the refresh field on the existing token.
          access_token.update(refresh: SecureRandom.base64(24))
        end

        settings = {access_token:  access_token.request,
                    expires_in:    (access_token.expires_at.to_i - Time.now.to_i),
                    refresh_token: access_token.refresh_code,
                    token_type:    :bearer}
        redirect URI.join(redirect_uri, "?#{URI.encode_www_form(settings)}").to_s 
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
    end

  end
end

