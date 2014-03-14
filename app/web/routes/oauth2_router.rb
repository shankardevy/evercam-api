require_relative "./web_router"
require '3scale_client'
require 'cgi'
require 'securerandom'

module Evercam
  class WebOAuth2Router < WebRouter

    # Recognised response types.
    VALID_RESPONSE_TYPES = ['code', 'token']

    # Error definitions.
    ACCESS_DENIED             = "access_denied"
    INVALID_REDIRECT_URI      = "invalid_redirect_uri"
    INVALID_REQUEST           = "invalid_request"
    INVALID_SCOPE             = "invalid_scope"
    SERVER_ERROR              = "server_error"
    TEMPORARILY_UNAVAILABLE   = "temporarily_unavailable"
    UNAUTHORIZED_CLIENT       = "unauthorized_client"
    UNSUPPORTED_RESPONSE_TYPE = "unsupported_response_type"

    helpers Sinatra::Jsonp

    helpers do
      # Used to test a specified response type against permitted values.
      def valid_response_type?(type)
        VALID_RESPONSE_TYPES.include?(type.to_s.strip.downcase)
      end

      # Used to test whether the specified redirect URI is valid.
      def valid_redirect_uri?(client, uri)
        client && client.callback_uris && client.callback_uris.find do |entry|
          entry[0,4] != "http" ? (entry == URI.parse(uri).host) : (entry == uri)
        end.nil? == false
      end

      # Take a single scope definition and translate it into a string.
      def interpret_scope(scope)
        resource, right, extent = scope.split(":")
        output = {right: right}
        if resource == 'cameras'
          output[:target] = "all of your existing cameras."
        elsif resource == "camera"
          output[:target] = "'#{extent}' camera."
        else
          raise INVALID_SCOPE
        end
        output
      end

      def parse_scope(scope)
        if scope
          scope.strip.include?(' ') ? scope.strip.split(' ') : [scope.strip]
        else
          []
        end
      end

      # Translate the scope request into a list of scope strings.
      def enumerate_rights(scopes)
        scopes.inject([]) {|list, scope| list << interpret_scope(scope); list}
      end

      # Used to check whether the request requires the addition of access rights.
      def has_all_rights?(client, token, user, scopes)
        missing_rights(client, token, user, scopes).size == 0
      end

      # Fetches a list of rights not currently held by a client.
      def missing_rights(client, token, user, scopes)
        rights_list = []
        scopes.each do |scope|
          type, right, target = scope.split(":")
          rights_list.concat(resources_for_scope(scope, user).inject([]) do |list, resource|
            list << scope if !AccessRightSet.for(resource, client).allow?(right)
            list
          end)
        end
        rights_list
      end

      # This method grants a client all rights that they currently don't have to
      # meet a list of scopes.
      def grant_missing_rights(client, token, user, scopes)
        missing_rights(client, token, user, scopes).each do |scope|
          type, right, target = scope.split(":")
          if AccessRight::ALL_SCOPES.include?(type)
            # Grant an account level right.
            AccountRightSet.new(user, client, type).grant(right)
          else
            # Grant individual resource rights.
            resources_for_scope(scope, user).each do |resource|
              AccessRightSet.for(resource, client).grant(right)
            end
          end
        end
      end

      # Fetches the list of resources that are associated with a scope.
      def resources_for_scope(scope, user)
        resources = []
        resource, right, target = scope.split(":")
        if resource == "cameras"
          Camera.where(owner: user).each do |camera|
            resources << camera if AccessRightSet.for(camera, user).allow?(right)
          end
        elsif resource == "camera"
          camera = Camera.where(exid: target).first
          if !camera.nil?
            resources << camera if AccessRightSet.for(camera, user).allow?(right)
          end
        else
          raise INVALID_SCOPE
        end
        resources
      end

      # Creates a Hash of response parameters for a redirect.
      def generate_response(token, response_type, state=nil)
        details = nil
        if response_type == 'code'
          details = {code:  token.refresh_code}
        elsif response_type == 'authorization_code'
          details  = {access_token:  token.request,
                      refresh_token: token.refresh_code,
                      token_type:    :bearer,
                      expires_in:    token.expires_in}
        else
          details  = {access_token: token.request,
                      token_type:   :bearer,
                      expires_in:   token.expires_in}
        end
        details[:state] = state if state
        details
      end

      # Generates a URI for responding to a rights request.
      def generate_response_uri(uri, token, response_type, state=nil)
        details = generate_response(token, response_type, state)
        if ['code', 'authorization_code'].include?(response_type)
          URI.join(uri, "?#{URI.encode_www_form(details)}")
        else
          URI.join(uri, "##{URI.encode_www_form(details)}")
        end
      end

      # Generates a URI for redirecting to an error.
      def generate_error_uri(uri, error)
        uri = URI.parse(uri)
        uri.query = URI.encode_www_form(error)
        uri
      end
    end

    # The fall back error page when a redirect is not possible.
    get '/oauth2/error' do
    end

    # This method gets hit when the user either approves or declines a rights
    # request.
    post '/oauth2/feedback' do
      redirect_uri = '/oauth2/error'
      begin
        raise ACCESS_DENIED if !params[:action]

        settings = session[:oauth]
        raise ACCESS_DENIED if settings.nil?
        session[:oauth] = nil
        redirect_uri  = settings[:redirect_uri]
        response_type = settings[:response_type]
        token         = AccessToken[settings[:access_token_id]]
        raise ACCESS_DENIED if token.nil?

        if params[:action].strip.downcase == 'approve'
          with_user do |user|
            client = Client[exid: settings[:client_id]]
            scopes = parse_scope(settings[:scope])
            grant_missing_rights(client, token, user, scopes)
            if redirect_uri
              redirect generate_response_uri(redirect_uri,
                                             token,
                                             response_type,
                                             settings[:state]).to_s
            else
              jsonp generate_response(token, response_type, settings[:state])
            end
          end
        else
          raise ACCESS_DENIED
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[1,20].join("\n")
        redirect generate_error_uri(redirect_uri, {error: error}).to_s
      end
    end

    # Step 1 of the authorization process for both the implicit and explicit
    # authorization flows.
    get '/oauth2/authorize' do
      redirect_uri    = '/oauth2/error'
      session[:oauth] = nil
      begin
        response_type = params[:response_type]
        raise INVALID_REDIRECT_URI if response_type == 'code' && !params[:redirect_uri]
        redirect_uri = params[:redirect_uri]

        raise UNSUPPORTED_RESPONSE_TYPE if !valid_response_type?(params[:response_type])
        raise INVALID_REQUEST if !params[:client_id]

        @client = Client.where(exid: params[:client_id]).first
        raise ACCESS_DENIED if @client.nil?
        raise INVALID_REDIRECT_URI if redirect_uri && !valid_redirect_uri?(@client, redirect_uri)

        scopes = parse_scope(params[:scope])

        with_user do |user|
          expiration = Time.now + (response_type == "token" ? 315569000 : 3600)
          token      = AccessToken.create(refresh:    SecureRandom.base64(24),
                                          client:     @client,
                                          grantor:    user,
                                          expires_at: expiration)

          if !has_all_rights?(@client, token, user, scopes)
            # Rights confirmation needed from user.
            session[:oauth] = {access_token_id: token.id,
                               client_id:       @client.exid,
                               response_type:   response_type,
                               scope:           params[:scope],
                               redirect_uri:    redirect_uri,
                               state:           params[:state]}
            @permissions = enumerate_rights(scopes)
            erb 'oauth2/authorize'.to_sym
          else
            # Request has all the rights needed, drop straight through.
            if redirect_uri
              redirect generate_response_uri(redirect_uri, token,
                                             response_type, params[:state]).to_s
            else
              jsonp generate_response(token, response_type, params[:state])
            end
          end
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[1,20].join("\n")
        if "#{error}" != INVALID_REDIRECT_URI
          redirect generate_error_uri(redirect_uri, {error: "#{error}"}).to_s
        else
          redirect generate_error_uri('/oauth2/error', {error: "#{error}"}).to_s
        end
      end
    end

    # Step 2 of the authorization process for the explicit flow only.
    post '/oauth2/authorize' do
      redirect_uri    = '/oauth2/error'
      session[:oauth] = nil
      begin
        redirect_uri = params[:redirect_uri]

        raise INVALID_REQUEST if params[:grant_type] != 'authorization_code'
        raise INVALID_REQUEST if !params[:code]
        raise INVALID_REQUEST if !params[:client_id]
        raise INVALID_REQUEST if !params[:client_secret]

        client = Client.where(exid: params[:client_id]).first
        raise UNAUTHORIZED_CLIENT if client.nil?
        raise INVALID_REDIRECT_URI if redirect_uri && !valid_redirect_uri?(client, redirect_uri)

        provider_key = Evercam::Config[:threescale][:provider_key]
        three_scale  = ::ThreeScale::Client.new(:provider_key => provider_key)
        response     = three_scale.authrep(app_id: client.exid,
                                           app_key: params[:client_secret])
        raise UNAUTHORIZED_CLIENT if !response.success?

        token = AccessToken.where(refresh: params[:code]).first
        raise ACCESS_DENIED if token.nil? 

        if redirect_uri
          redirect generate_response_uri(redirect_uri, token,
                                         'authorization_code',
                                         params[:state]).to_s
        else
          jsonp generate_response(token, 'authorization_code', params[:state])
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[1,20].join("\n")
        if "#{error}" != INVALID_REDIRECT_URI
          redirect generate_error_uri(redirect_uri, {error: "#{error}"}).to_s
        else
          redirect generate_error_uri('/oauth2/error', {error: "#{error}"}).to_s
        end
      end
    end

    # Fetch details for an allocated token.
    get '/oauth2/tokeninfo' do
      output = {error: INVALID_REQUEST}
      code   = 400
      if params[:access_token]
        token = AccessToken.where(request: params[:access_token]).first
        if token && !token.client_id.nil?
          output = {access_token: token.request,
                    audience:     token.client.exid,
                    expires_in:   token.expires_in}
          output[:userid] = token.grantor.username if token.grantor_id
          code = 200
        end
      end
      status code
      jsonp output
    end

    # Revoke an existing client token.
    get '/oauth2/revoke' do
      output = {error: INVALID_REQUEST}
      code   = 400
      if params[:access_token]
        token = AccessToken.where(request: params[:access_token]).first
        if token && !token.client_id.nil?
          token.update(is_revoked: true) if !token.is_revoked?
          output = {}
          code   = 200
        end
      end
      status code
      jsonp output
    end
  end
end