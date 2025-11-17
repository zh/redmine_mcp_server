# frozen_string_literal: true

module RedmineMcpServer
  # MCP Protocol Adapter
  # Translates JSON-RPC 2.0 method calls to McpServer operations
  # Implements MCP protocol specification (2025-06-18)
  class McpProtocolAdapter
    # MCP protocol version we support
    PROTOCOL_VERSION = '2025-06-18'

    # Server information
    SERVER_NAME = 'Redmine MCP Server'
    SERVER_VERSION = '0.1.0'

    def initialize(mcp_server, logger)
      @mcp_server = mcp_server
      @logger = logger
      @initialized = false
      @client_info = nil
    end

    # Handle a JSON-RPC request message
    # @param message [Hash] Parsed JSON-RPC message with symbolized keys
    # @return [Hash, nil] JSON-RPC response (nil for notifications)
    def handle_request(message)
      method = message[:method]
      params = message[:params] || {}
      id = message[:id]

      # Check if this is a notification (no id field)
      if id.nil?
        handle_notification(method, params)
        return nil
      end

      # Require initialization for most methods (except initialize and ping)
      unless @initialized || method == 'initialize' || method == 'ping'
        raise JsonRpcHandler::JsonRpcError.new(
          -32_002,
          'Not initialized',
          'Server must be initialized before calling other methods'
        )
      end

      # Route to appropriate handler
      result = route_method(method, params)

      # Return JSON-RPC response
      {
        jsonrpc: '2.0',
        id: id,
        result: result
      }
    rescue JsonRpcHandler::JsonRpcError
      # Re-raise JSON-RPC errors
      raise
    rescue StandardError => e
      # Wrap unexpected errors as Internal Error
      @logger.error "Error handling #{method}: #{e.message}"
      @logger.error e.backtrace.join("\n")
      raise JsonRpcHandler::JsonRpcError.new(
        JsonRpcHandler::INTERNAL_ERROR,
        "Internal error: #{e.message}"
      )
    end

    private

    # Route method to appropriate handler
    # @param method [String] JSON-RPC method name
    # @param params [Hash] Method parameters
    # @return [Hash] Method result
    def route_method(method, params)
      case method
      when 'initialize'
        handle_initialize(params)
      when 'ping'
        handle_ping(params)
      when 'tools/list'
        handle_tools_list(params)
      when 'tools/call'
        handle_tools_call(params)
      when 'resources/list'
        handle_resources_list(params)
      when 'resources/read'
        handle_resources_read(params)
      else
        raise JsonRpcHandler::JsonRpcError.new(
          JsonRpcHandler::METHOD_NOT_FOUND,
          "Method not found: #{method}"
        )
      end
    end

    # Handle initialization request
    # @param params [Hash] Must contain protocolVersion, capabilities, clientInfo
    # @return [Hash] Server capabilities and info
    def handle_initialize(params)
      client_version = params[:protocolVersion] || params['protocolVersion']
      @client_info = params[:clientInfo] || params['clientInfo']

      # Log client information
      if @client_info
        client_name = @client_info[:name] || @client_info['name']
        client_ver = @client_info[:version] || @client_info['version']
        @logger.info "Client: #{client_name} #{client_ver}"
      end

      # Version negotiation
      if client_version != PROTOCOL_VERSION
        @logger.warn "Protocol version mismatch: client=#{client_version}, server=#{PROTOCOL_VERSION}"
        @logger.warn 'Will attempt to continue with server version'
      end

      # Return server capabilities
      {
        protocolVersion: PROTOCOL_VERSION,
        capabilities: build_capabilities,
        serverInfo: {
          name: SERVER_NAME,
          version: SERVER_VERSION
        }
      }
    end

    # Build server capabilities based on registered tools/resources
    # @return [Hash] Capabilities object
    def build_capabilities
      capabilities = {}

      # Tools capability (we have tools)
      capabilities[:tools] = {} if @mcp_server.tools.any?

      # Resources capability (we have resources)
      if @mcp_server.resources.any?
        capabilities[:resources] = {
          subscribe: false,  # We don't support subscriptions yet
          listChanged: false # We don't send list changed notifications yet
        }
      end

      # Logging capability (we support logging)
      capabilities[:logging] = {}

      capabilities
    end

    # Handle notification messages (no response expected)
    # @param method [String] Notification method
    # @param params [Hash] Notification parameters
    def handle_notification(method, params)
      case method
      when 'notifications/initialized'
        @initialized = true
        @logger.info 'Client sent initialized notification - server is now operational'
      when 'notifications/cancelled'
        # Client cancelled a request
        request_id = params[:requestId] || params['requestId']
        @logger.info "Client cancelled request: #{request_id}"
        # TODO: Implement request cancellation
      else
        @logger.warn "Unknown notification: #{method}"
      end
    end

    # Handle ping request (keep-alive)
    # @param params [Hash] Ping parameters (unused)
    # @return [Hash] Empty result
    def handle_ping(_params)
      {}
    end

    # Handle tools/list request
    # @param params [Hash] List parameters (unused currently)
    # @return [Hash] List of available tools
    def handle_tools_list(_params)
      tools = @mcp_server.list_tools
      { tools: tools }
    end

    # Handle tools/call request
    # @param params [Hash] Must contain name and arguments
    # @return [Hash] Tool execution result in MCP format
    def handle_tools_call(params)
      tool_name = params[:name] || params['name']
      arguments = params[:arguments] || params['arguments'] || {}

      unless tool_name
        raise JsonRpcHandler::JsonRpcError.new(
          JsonRpcHandler::INVALID_PARAMS,
          'Missing required parameter: name'
        )
      end

      # Find the tool using O(1) hash lookup
      tool = @mcp_server.tools_by_name[tool_name]

      unless tool
        raise JsonRpcHandler::JsonRpcError.new(
          JsonRpcHandler::METHOD_NOT_FOUND,
          "Tool not found: #{tool_name}"
        )
      end

      # Execute the tool with MCP format
      @logger.info "Calling tool: #{tool_name}"
      tool.call_for_mcp(arguments)
    end

    # Handle resources/list request
    # @param params [Hash] List parameters (unused currently)
    # @return [Hash] List of available resources
    def handle_resources_list(_params)
      resources = @mcp_server.list_resources
      { resources: resources }
    end

    # Handle resources/read request
    # @param params [Hash] Must contain uri
    # @return [Hash] Resource contents in MCP format
    def handle_resources_read(params)
      uri = params[:uri] || params['uri']

      unless uri
        raise JsonRpcHandler::JsonRpcError.new(
          JsonRpcHandler::INVALID_PARAMS,
          'Missing required parameter: uri'
        )
      end

      # Find the resource using O(1) hash lookup
      resource = @mcp_server.resources_by_uri[uri]

      unless resource
        raise JsonRpcHandler::JsonRpcError.new(
          -32_002, # Resource not found (MCP-specific error code)
          "Resource not found: #{uri}"
        )
      end

      # Read the resource with MCP format
      @logger.info "Reading resource: #{uri}"
      resource.read_for_mcp
    end
  end
end
