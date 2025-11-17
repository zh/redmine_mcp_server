# frozen_string_literal: true

require 'logger'
require 'rack'
require 'json'
require 'dotenv'

# Load environment variables from .env file
# This ensures .env is loaded in both stdio (MCP) and HTTP modes
Dotenv.load(File.expand_path('../.env', __dir__))

require_relative 'async_redmine_client'
require_relative 'mcp_server'
require_relative 'resources/base_resource'
require_relative 'tools'

# Main module for Redmine MCP Server
module RedmineMcpServer
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class RedmineAPIError < Error; end

  class << self
    attr_accessor :logger, :config, :redmine_client, :mcp_server

    def configure
      @config = {
        redmine_url: ENV.fetch('REDMINE_URL'),
        redmine_api_key: ENV.fetch('REDMINE_API_KEY'),
        mcp_port: ENV.fetch('MCP_PORT', '3100').to_i,
        mcp_host: ENV.fetch('MCP_HOST', 'localhost'),
        log_level: ENV.fetch('LOG_LEVEL', 'info').to_sym,
        mode: ENV.fetch('MCP_MODE', 'http')
      }

      # Mode-aware logging: STDIO mode logs to stderr, HTTP mode logs to stdout
      log_output = stdio_mode? ? $stderr : $stdout
      @logger = Logger.new(log_output)
      @logger.level = Logger.const_get(config[:log_level].to_s.upcase)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "[#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{severity}: #{msg}\n"
      end

      validate_configuration!
      @config
    rescue KeyError => e
      raise ConfigurationError, "Missing required environment variable: #{e.message}"
    end

    def stdio_mode?
      ENV['MCP_MODE'] == 'stdio'
    end

    def http_mode?
      !stdio_mode?
    end

    private

    def validate_configuration!
      raise ConfigurationError, 'REDMINE_URL must be set' if config[:redmine_url].to_s.empty?

      raise ConfigurationError, 'REDMINE_API_KEY must be set' if config[:redmine_api_key].to_s.empty?

      return if config[:redmine_url] =~ %r{\Ahttps?://}

      raise ConfigurationError, 'REDMINE_URL must start with http:// or https://'
    end
  end

  # Rack application factory
  # @return [Proc] Rack application
  def self.create_app
    @mcp_server.to_rack_app
  end

  # Alias for compatibility
  Application = method(:create_app)
end

# Initialize configuration
RedmineMcpServer.configure

# Initialize Async Redmine client
RedmineMcpServer.redmine_client = RedmineMcpServer::AsyncRedmineClient.new(
  RedmineMcpServer.config[:redmine_url],
  RedmineMcpServer.config[:redmine_api_key],
  logger: RedmineMcpServer.logger
)

# Initialize MCP server
RedmineMcpServer.mcp_server = RedmineMcpServer::McpServer.new

RedmineMcpServer.logger.info 'Redmine MCP Server initialized'
RedmineMcpServer.logger.info "Connecting to Redmine at: #{RedmineMcpServer.config[:redmine_url]}"

# Test connection to Redmine
begin
  if RedmineMcpServer.redmine_client.test_connection
    RedmineMcpServer.logger.info 'Successfully connected to Redmine API'
  end
rescue RedmineMcpServer::AsyncRedmineClient::RedmineError => e
  RedmineMcpServer.logger.warn "Could not connect to Redmine: #{e.message}"
  RedmineMcpServer.logger.warn 'Server will start, but Redmine operations will fail'
end

# Register all implemented tools
# Set to true to register ALL tools including skeletons (for testing)
register_skeletons = ENV.fetch('MCP_REGISTER_SKELETONS', 'false') == 'true'

if register_skeletons
  RedmineMcpServer::Tools.register_all_including_skeletons(RedmineMcpServer.mcp_server)
  RedmineMcpServer.logger.warn 'All tools registered including skeletons (many will raise NotImplementedError)'
else
  RedmineMcpServer::Tools.register_all_implemented(RedmineMcpServer.mcp_server)
end

RedmineMcpServer.logger.info "MCP server ready with #{RedmineMcpServer.mcp_server.tools.size} tools registered"
