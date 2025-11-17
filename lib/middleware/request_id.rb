# frozen_string_literal: true

require 'securerandom'

module RedmineMcpServer
  module Middleware
    # Rack middleware that adds request ID tracking for debugging and correlation
    class RequestId
      def initialize(app)
        @app = app
      end

      def call(env)
        # Generate or use existing request ID
        request_id = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
        env['HTTP_X_REQUEST_ID'] = request_id

        # Log the request with ID
        logger = RedmineMcpServer.logger
        logger.info "[#{request_id}] #{env['REQUEST_METHOD']} #{env['PATH_INFO']}"

        # Call the next middleware/app
        status, headers, body = @app.call(env)

        # Add request ID to response headers
        headers['X-Request-ID'] = request_id

        [status, headers, body]
      rescue StandardError => e
        # Ensure request ID is logged even on errors
        logger.error "[#{request_id}] Error: #{e.class} - #{e.message}"
        raise
      end
    end
  end
end
