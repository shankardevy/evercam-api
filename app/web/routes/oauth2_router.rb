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
        scope.strip.include?(' ') ? scope.strip.split(' ') : [scope.strip]
      end

      # Translate the scope request into a list of scope strings.
      def enumerate_rights(scopes)
        scopes.inject([]) {|list, scope| list << interpret_scope(scope); list}
      end

      # Used to check whether the request requires the addition of access rights.
      def has_all_rights?(client, user, scopes)
        missing_rights(client, user, scopes).size == 0
      end

      # Fetches a list of rights not currently held by a client.
      def missing_rights(client, user, scopes)
        access_token(client)
        rights_list = []
        scopes.each do |scope|
          type, right, target = scope.split(":")
          rights_list.concat(resources_for_scope(scope, user).inject([]) do |list, resource|
            list << scope if !AccessRightSet.new(resource, client).allow?(right)
            list
          end)
        end
        rights_list
      end

      # This method grants a client all rights that they currently don't have to
      # meet a list of scopes.
      def grant_missing_rights(client, user, scopes)
        missing_rights(client, user, scopes).each do |scope|
          type, right, target = scope.split(":")
          resources_for_scope(scope, user).each do |resource|
            AccessRightSet.new(resource, client).grant(right)
          end
        end
      end

      # Fetches the list of resources that are associated with a scope.
      def resources_for_scope(scope, user)
        resources = []
        resource, right, target = scope.split(":")
        if resource == "cameras"
          Camera.where(owner: user).each do |camera|
            resources << camera if AccessRightSet.new(camera, user).allow?(right)
          end
        elsif resource == "camera"
          camera = Camera.where(exid: target).first
          if !camera.nil?
            resources << camera if AccessRightSet.new(camera, user).allow?(right)
          end
        else
          raise INVALID_SCOPE
        end
        resources
      end

      # Creates a Hash of response parameters for a redirect.
      def generate_response(client, response_type, state=nil)
        details = nil
        token   = access_token(client)
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
      def generate_response_uri(uri, client, response_type, state=nil)
        details = generate_response(client, response_type, state)
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

      # Get the access_token for a client, creating a new one if it is needed.
      def access_token(client)
        token = nil
        query = AccessToken.where(is_revoked: false, client: client).order(Sequel.desc(:created_at))
        if query.count > 0
          token = query.first
          token = nil if !token.is_valid?
        end
        token = AccessToken.create(client: client, refresh: SecureRandom.base64(24)) if token.nil?
        token
      end
    end

    # The fall back error page when a redirect is not possible.
    get '/oauth2/error' do
    end

    # This method gets hit when the user either approves or declines a rights
    # request.
    get '/oauth2/feedback' do
      redirect_uri = '/oauth2/error'
      begin
        raise ACCESS_DENIED if !params[:action]

        settings = session[:oauth]
        raise ACCESS_DENIED if settings.nil?
        session[:oauth] = nil
        redirect_uri  = settings[:redirect_uri]
        response_type = settings[:response_type]

        if params[:action].strip.downcase == 'approve'
          with_user do |user|
            client = Client[exid: settings[:client_id]]
            scopes = parse_scope(settings[:scope])
            grant_missing_rights(client, user, scopes)
            if redirect_uri
              redirect generate_response_uri(redirect_uri,
                                             client,
                                             response_type,
                                             settings[:state]).to_s
            else
              jsonp generate_response(client, response_type, settings[:state])
            end
          end
        else
          raise ACCESS_DENIED
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
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
        raise INVALID_REQUEST if !params[:scope]

        @client = Client.where(exid: params[:client_id]).first
        raise ACCESS_DENIED if @client.nil?
        raise INVALID_REDIRECT_URI if redirect_uri && !valid_redirect_uri?(@client, redirect_uri)

        scopes = parse_scope(params[:scope])

        with_user do |user|
          if !has_all_rights?(@client, user, scopes)
            # Rights confirmation needed from user.
            session[:oauth] = {client_id:     @client.id,
                               response_type: response_type,
                               scope:         params[:scope],
                               redirect_uri:  redirect_uri,
                               state:         params[:state]}
            @permissions = enumerate_rights(scopes)
            erb 'oauth2/authorize'.to_sym
          else
            # Request has all the rights needed, drop straight through.
            if redirect_uri
              redirect generate_response_uri(redirect_uri, @client,
                                             response_type, params[:state]).to_s
            else
              jsonp generate_response(@client, response_type, params[:state])
            end
          end
        end
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
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
        raise INVALID_REQUEST if !params[:redirect_uri]
        redirect_uri = params[:redirect_uri]

        raise INVALID_REQUEST if params[:grant_type] != 'authorization_code'
        raise INVALID_REQUEST if !params[:code]
        raise INVALID_REQUEST if !params[:client_id]
        raise INVALID_REQUEST if !params[:client_secret]

        client = Client.where(exid: params[:client_id]).first
        raise UNAUTHORIZED_CLIENT if client.nil?
        raise INVALID_REDIRECT_URI if !valid_redirect_uri?(client, redirect_uri)

        provider_key = Evercam::Config[:threescale][:provider_key]
        three_scale  = ::ThreeScale::Client.new(:provider_key => provider_key)
        response     = three_scale.authrep(app_id: client.exid,
                                           app_key: params[:client_secret])
        raise UNAUTHORIZED_CLIENT if !response.success?

        redirect generate_response_uri(redirect_uri, client,
                                       'authorization_code',
                                       params[:state]).to_s
      rescue => error
        #puts "ERROR: #{error}\n" + error.backtrace[0,5].join("\n")
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
          with_user do |user|
            output = {access_token: token.request,
                      audience:     token.client.exid,
                      expires_in:   token.expires_in,
                      userid:       user.username}
            code = 200
          end
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