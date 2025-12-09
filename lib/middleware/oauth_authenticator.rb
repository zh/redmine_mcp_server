# frozen_string_literal: true

module RedmineMcpServer
  module Middleware
    # Rack middleware that extracts OAuth Bearer tokens from requests
    # and creates per-request Redmine clients for ChatGPT Actions mode
    #
    # This middleware:
    # 1. Extracts Bearer token from Authorization header
    # 2. Creates a per-request AsyncRedmineClient with Bearer auth
    # 3. Stores the client in env for downstream use
    # 4. Falls back to default API key client if no Bearer token
    class OAuthAuthenticator
      # Env key where per-request client is stored
      ENV_CLIENT_KEY = 'redmine_mcp.client'
      ENV_AUTH_TYPE_KEY = 'redmine_mcp.auth_type'
      ENV_USER_TOKEN_KEY = 'redmine_mcp.user_token'

      # Paths that don't require authentication
      PUBLIC_PATHS = %w[
        /health
        /.well-known/ai-plugin.json
        /api/v1/openapi.json
        /api/v1/openapi.yaml
      ].freeze

      def initialize(app, options = {})
        @app = app
        @logger = options[:logger] || RedmineMcpServer.logger
        @require_auth = options.fetch(:require_auth, false)
      end

      def call(env)
        request = Rack::Request.new(env)

        # Skip auth for public paths
        if public_path?(request.path)
          env[ENV_AUTH_TYPE_KEY] = :none
          return @app.call(env)
        end

        # Extract Bearer token from Authorization header
        bearer_token = extract_bearer_token(env)

        if bearer_token
          # Create per-request client with Bearer token
          client = create_bearer_client(bearer_token)
          env[ENV_CLIENT_KEY] = client
          env[ENV_AUTH_TYPE_KEY] = :bearer
          env[ENV_USER_TOKEN_KEY] = bearer_token
          @logger.debug 'OAuth: Using Bearer token authentication'
        elsif @require_auth
          # No token and auth required - return 401
          @logger.warn "OAuth: No Bearer token provided for protected path: #{request.path}"
          return unauthorized_response('Bearer token required')
        else
          # Fall back to default API key client
          env[ENV_CLIENT_KEY] = RedmineMcpServer.redmine_client
          env[ENV_AUTH_TYPE_KEY] = :api_key
          @logger.debug 'OAuth: Using default API key authentication'
        end

        @app.call(env)
      rescue StandardError => e
        @logger.error "OAuth middleware error: #{e.class} - #{e.message}"
        raise
      end

      private

      # Extract Bearer token from Authorization header
      # @param env [Hash] Rack environment
      # @return [String, nil] Bearer token or nil if not found
      def extract_bearer_token(env)
        auth_header = env['HTTP_AUTHORIZATION']
        return nil unless auth_header

        # Match "Bearer <token>" format (case-insensitive)
        match = auth_header.match(/\ABearer\s+(.+)\z/i)
        match&.[](1)
      end

      # Create a new Redmine client with Bearer token authentication
      # @param token [String] OAuth Bearer token
      # @return [AsyncRedmineClient] Client configured for Bearer auth
      def create_bearer_client(token)
        AsyncRedmineClient.new(
          RedmineMcpServer.config[:redmine_url],
          token,
          auth_type: AsyncRedmineClient::AUTH_TYPE_BEARER,
          logger: @logger
        )
      end

      # Check if path is public (doesn't require auth)
      # @param path [String] Request path
      # @return [Boolean] true if public path
      def public_path?(path)
        PUBLIC_PATHS.include?(path) || path == '/'
      end

      # Build 401 Unauthorized response
      # @param message [String] Error message
      # @return [Array] Rack response tuple
      def unauthorized_response(message)
        body = JSON.generate({
                               error: 'Unauthorized',
                               message: message
                             })

        [
          401,
          {
            'Content-Type' => 'application/json',
            'WWW-Authenticate' => 'Bearer realm="Redmine MCP API"'
          },
          [body]
        ]
      end
    end
  end
end
