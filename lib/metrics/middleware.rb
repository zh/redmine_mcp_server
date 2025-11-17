# frozen_string_literal: true

module RedmineMcpServer
  module Metrics
    # Rack middleware for collecting HTTP request metrics
    class Middleware
      def initialize(app, collector)
        @app = app
        @collector = collector
      end

      def call(env)
        start_time = Time.now
        request = Rack::Request.new(env)

        # Call the next middleware/app
        status, headers, body = @app.call(env)

        # Calculate request duration
        duration = Time.now - start_time

        # Record metrics
        record_request_metrics(
          method: request.request_method,
          path: request.path,
          status: status,
          duration: duration
        )

        [status, headers, body]
      rescue StandardError
        # Record error metrics
        duration = Time.now - start_time
        record_request_metrics(
          method: request.request_method,
          path: request.path,
          status: 500,
          duration: duration
        )
        raise
      end

      private

      def record_request_metrics(method:, path:, status:, duration:)
        # Normalize path to remove IDs and group similar requests
        normalized_path = normalize_path(path)

        @collector.record_api_call(normalized_path, method, duration, status)
      end

      def normalize_path(path)
        # Replace numeric IDs with placeholders for better grouping
        path.gsub(%r{/\d+}, '/:id')
            .gsub(/\?.*$/, '') # Remove query string
      end
    end
  end
end
