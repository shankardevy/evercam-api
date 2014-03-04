require_relative "./web_router"
require '3scale_client'
require 'cgi'
require 'securerandom'

module Evercam
  class WebOAuth2Router < WebRouter

    helpers Sinatra::Jsonp

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
        raise BadRequestError if params[:grant_type] != "authorization_code"

        client = Client.where(exid: params[:client_id]).first
        raise BadRequestError if client.nil?

        client_id     = CGI.unescape(params[:client_id])
        client_secret = CGI.unescape(params[:client_secret])
        code          = CGI.unescape(params[:code])

        three_scale = ::ThreeScale::Client.new(:provider_key => Evercam::Config[:threescale][:provider_key])
        response    = three_scale.authrep(app_id: client_id,
                                          app_key: client_secret)
        raise BadRequestError if !response.success?

        redirect_uri = params[:redirect_uri]
        redirect_uri = CGI.unescape(redirect_uri) if !redirect_uri.nil?

        access_token = AccessToken.where(client_id: client.id,
                                         refresh:   code).first
        raise BadRequestError if access_token.nil?
        raise BadRequestError if access_token.is_revoked?

        if access_token.is_expired?
          # Issue new access token.
          access_token = AccessToken.create(client: client_id)
        else
          # Change the refresh field on the existing token.
          access_token.update(refresh: SecureRandom.base64(24))
        end

        remaining = access_token.expires_at.to_i - Time.now.to_i
        remaining = 0 if remaining < 0
        settings = {access_token:  access_token.request,
                    expires_in:    remaining,
                    refresh_token: access_token.refresh_code,
                    token_type:    :bearer}
        if redirect_uri
          redirect URI.join(redirect_uri, "?#{URI.encode_www_form(settings)}").to_s 
        else
          jsonp settings
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
    end

    get '/oauth2/tokeninfo' do
      response = {error: "invalid_token"}
      begin
        if !curr_user.nil?
          raise BadRequestError if [nil, ''].include?(params[:code])

          access_token = AccessToken.where(refresh: params[:code]).first
          if !access_token.nil? && access_token.is_valid?
            remaining = access_token.expires_at.to_i - Time.now.to_i
            remaining = 0 if remaining < 0
            response = {audience:   access_token.client.exid,
                        access_token: access_token.request,
                        expires_in: remaining,
                        userid:     curr_user.username}
          end
        end

        if params[:redirect_uri]
          redirect URI.join(params[:redirect_uri], "?#{URI.encode_www_form(response)}").to_s
        else
          jsonp response
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
    end

    get '/oauth2/revoke' do
      response = {}
      begin
        raise BadRequestError if [nil, ''].include?(params[:token])

        access_token = AccessToken.where(request: params[:token]).first
        access_token = AccessToken.where(refresh: params[:token]).first if access_token.nil?
        raise NotFoundError if access_token.nil?

        access_token.update(is_revoked: true) if !access_token.is_revoked?
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
        raise error
      end
      jsonp response
    end

  end
end

