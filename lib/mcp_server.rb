# frozen_string_literal: true

require 'securerandom'
require_relative 'metrics/collector'
require_relative 'metrics/middleware'
require_relative 'middleware/request_id'

module RedmineMcpServer
  # MCP Server implementation
  class McpServer
    attr_reader :tools, :resources, :metrics_collector, :tools_by_name, :resources_by_uri

    def initialize
      @tools = []
      @tools_by_name = {} # O(1) lookup hash
      @resources = []
      @resources_by_uri = {} # O(1) lookup hash
      @logger = RedmineMcpServer.logger
      @metrics_collector = Metrics::Collector.new
    end

    # Register a tool
    # @param tool [Tools::BaseTool] Tool instance
    def register_tool(tool)
      # Inject metrics collector into the tool
      tool.instance_variable_set(:@metrics_collector, @metrics_collector)
      @tools << tool
      @tools_by_name[tool.name] = tool # O(1) lookup hash
      @logger.info "Registered tool: #{tool.name}"
    end

    # Register a resource
    # @param resource [Resources::BaseResource] Resource instance
    def register_resource(resource)
      @resources << resource
      @resources_by_uri[resource.uri] = resource # O(1) lookup hash
      @logger.info "Registered resource: #{resource.uri}"
    end

    # Get MCP server information
    # @return [Hash] Server info for MCP protocol
    def server_info
      {
        name: 'Redmine MCP Server',
        version: '0.1.0',
        description: 'Model Context Protocol server for Redmine',
        capabilities: {
          tools: {},
          resources: {}
        }
      }
    end

    # List all available tools
    # @return [Array<Hash>] Tool definitions in MCP format
    def list_tools
      @tools.map(&:to_mcp)
    end

    # List all available resources
    # @return [Array<Hash>] Resource definitions in MCP format
    def list_resources
      @resources.map(&:to_mcp)
    end

    # Call a tool by name
    # @param tool_name [String] Name of the tool to call
    # @param params [Hash] Tool parameters
    # @return [Hash] Tool execution result
    def call_tool(tool_name, params = {})
      tool = @tools_by_name[tool_name] # O(1) hash lookup

      unless tool
        @logger.error "Tool not found: #{tool_name}"
        return {
          success: false,
          error: {
            type: 'ToolNotFoundError',
            message: "Tool '#{tool_name}' not found. Available tools: #{@tools.map(&:name).join(', ')}"
          }
        }
      end

      tool.call(params)
    end

    # Read a resource by URI
    # @param uri [String] Resource URI
    # @return [Hash] Resource contents
    def read_resource(uri)
      resource = @resources_by_uri[uri] # O(1) hash lookup

      unless resource
        @logger.error "Resource not found: #{uri}"
        return {
          success: false,
          error: {
            type: 'ResourceNotFoundError',
            message: "Resource '#{uri}' not found"
          }
        }
      end

      resource.read
    end

    # Convert to Rack application
    # @return [Proc] Rack application
    def to_rack_app
      mcp_server = self
      metrics_collector = @metrics_collector

      app = proc do |env|
        request = Rack::Request.new(env)

        begin
          case [request.request_method, request.path]
          when ['GET', '/'], ['GET', '/health']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             status: 'ok',
                                                                             service: 'Redmine MCP Server',
                                                                             version: '0.1.0',
                                                                             tools_count: mcp_server.tools.size,
                                                                             resources_count: mcp_server.resources.size,
                                                                             redmine_url: RedmineMcpServer.config[:redmine_url],
                                                                             timestamp: Time.now.iso8601
                                                                           })]]

          when ['GET', '/mcp/info']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate(mcp_server.server_info)]]

          when ['GET', '/mcp/tools']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             tools: mcp_server.list_tools
                                                                           })]]

          when ['GET', '/mcp/resources']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             resources: mcp_server.list_resources
                                                                           })]]

          when ['POST', '/mcp/tools/call']
            body = JSON.parse(request.body.read)
            result = mcp_server.call_tool(body['name'], body['params'] || {})
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate(result)]]

          when ['POST', '/mcp/resources/read']
            body = JSON.parse(request.body.read)
            result = mcp_server.read_resource(body['uri'])
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate(result)]]

          # Metrics endpoints
          when ['GET', '/metrics']
            [200, { 'Content-Type' => 'text/plain; version=0.0.4' }, [metrics_collector.prometheus_format]]

          when ['GET', '/metrics/tools']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             tools: metrics_collector.tool_summary
                                                                           })]]

          when ['GET', '/metrics/api']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             api_calls: metrics_collector.api_summary
                                                                           })]]

          when ['GET', '/metrics/slow']
            [200, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             slow_requests: metrics_collector.slow_requests_summary
                                                                           })]]

          else
            [404, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                             error: 'Not Found',
                                                                             path: request.path,
                                                                             method: request.request_method
                                                                           })]]
          end
        rescue JSON::ParserError => e
          error_id = SecureRandom.uuid
          RedmineMcpServer.logger.error "JSON Parse Error #{error_id}: #{e.message}"

          [400, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                           error: 'Invalid JSON',
                                                                           message: e.message,
                                                                           error_id: error_id
                                                                         })]]
        rescue StandardError => e
          error_id = SecureRandom.uuid
          RedmineMcpServer.logger.error "Server error #{error_id}: #{e.class} - #{e.message}"
          RedmineMcpServer.logger.error e.backtrace.first(10).join("\n")

          # Sanitize error message in production
          error_message = if RedmineMcpServer.config[:rack_env] == 'production'
                            "Internal error occurred. Please contact support with error ID: #{error_id}"
                          else
                            e.message
                          end

          [500, { 'Content-Type' => 'application/json' }, [JSON.generate({
                                                                           error: 'Internal Server Error',
                                                                           message: error_message,
                                                                           error_id: error_id
                                                                         })]]
        end
      end

      # Wrap app with middleware (order matters: outer to inner)
      app = Metrics::Middleware.new(app, metrics_collector)
      Middleware::RequestId.new(app)
    end
  end
end
