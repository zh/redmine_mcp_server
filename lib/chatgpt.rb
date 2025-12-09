# frozen_string_literal: true

# ChatGPT Actions support module
# Provides REST API, OpenAPI schema, and OAuth integration for ChatGPT

require_relative 'chatgpt/rest_api_router'
require_relative 'chatgpt/openapi_generator'
require_relative 'chatgpt/manifest_generator'

module RedmineMcpServer
  module ChatGPT
    class << self
      # Check if ChatGPT mode is enabled
      # @return [Boolean]
      def enabled?
        ENV.fetch('CHATGPT_MODE', 'false') == 'true'
      end

      # Get configuration for ChatGPT mode
      # @return [Hash]
      def config
        {
          enabled: enabled?,
          server_url: ENV.fetch('OPENAPI_SERVER_URL', 'http://localhost:3100'),
          redmine_url: RedmineMcpServer.config[:redmine_url],
          require_auth: ENV.fetch('CHATGPT_REQUIRE_AUTH', 'false') == 'true'
        }
      end
    end
  end
end
