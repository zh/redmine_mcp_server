# frozen_string_literal: true

require 'json'

module RedmineMcpServer
  module ChatGPT
    # REST API router for ChatGPT Actions
    # Maps HTTP REST requests to MCP tool calls
    #
    # Supports two routing modes:
    # 1. Generic tool endpoint: POST /api/v1/tools/{tool_name}
    # 2. Resource-based REST: GET/POST/PUT/DELETE /api/v1/{resource}[/{id}]
    class RestApiRouter
      # Resource to tool mapping for REST-style endpoints
      RESOURCE_ROUTES = {
        # Issues
        ['GET', 'issues', nil] => 'list_issues',
        ['POST', 'issues', nil] => 'create_issue',
        ['GET', 'issues', :id] => 'get_issue',
        ['PUT', 'issues', :id] => 'update_issue',
        ['DELETE', 'issues', :id] => 'delete_issue',

        # Projects
        ['GET', 'projects', nil] => 'list_projects',
        ['POST', 'projects', nil] => 'create_project',
        ['GET', 'projects', :id] => 'get_project',
        ['PUT', 'projects', :id] => 'update_project',
        ['DELETE', 'projects', :id] => 'delete_project',

        # Time entries
        ['GET', 'time_entries', nil] => 'list_time_entries',
        ['POST', 'time_entries', nil] => 'create_time_entry',
        ['GET', 'time_entries', :id] => 'get_time_entry',
        ['PUT', 'time_entries', :id] => 'update_time_entry',
        ['DELETE', 'time_entries', :id] => 'delete_time_entry',

        # Users
        ['GET', 'users', nil] => 'list_users',
        ['GET', 'users', :id] => 'get_user',

        # Versions
        ['GET', 'versions', nil] => 'list_versions',
        ['POST', 'versions', nil] => 'create_version',
        ['GET', 'versions', :id] => 'get_version',
        ['PUT', 'versions', :id] => 'update_version',
        ['DELETE', 'versions', :id] => 'delete_version',

        # Memberships
        ['GET', 'memberships', nil] => 'list_memberships',
        ['POST', 'memberships', nil] => 'create_membership',
        ['GET', 'memberships', :id] => 'get_membership',
        ['DELETE', 'memberships', :id] => 'delete_membership',

        # Groups
        ['GET', 'groups', nil] => 'list_groups',
        ['GET', 'groups', :id] => 'get_group',

        # Queries
        ['GET', 'queries', nil] => 'list_queries',

        # Custom fields
        ['GET', 'custom_fields', nil] => 'list_custom_fields'
      }.freeze

      # ID parameter name mapping for each resource
      RESOURCE_ID_PARAM = {
        'issues' => :id,
        'projects' => :id,
        'time_entries' => :time_entry_id,
        'users' => :id,
        'versions' => :version_id,
        'memberships' => :membership_id,
        'groups' => :id
      }.freeze

      def initialize(mcp_server, logger: nil)
        @mcp_server = mcp_server
        @logger = logger || RedmineMcpServer.logger
      end

      # Route a request to the appropriate tool
      # @param request [Rack::Request] The incoming request
      # @param env [Hash] Rack environment (contains per-request client)
      # @return [Array] Rack response [status, headers, body]
      def route(request, env)
        path = request.path
        method = request.request_method

        # Extract client from env (set by OAuth middleware)
        client = env[Middleware::OAuthAuthenticator::ENV_CLIENT_KEY]

        # Try to match the request
        result = if path.start_with?('/api/v1/tools/')
                   handle_generic_tool_call(request, method, path, client)
                 elsif path.start_with?('/api/v1/')
                   handle_resource_route(request, method, path, client)
                 end

        if result
          format_response(result)
        else
          not_found_response(path, method)
        end
      rescue JSON::ParserError => e
        error_response(400, 'Invalid JSON', e.message)
      rescue ArgumentError => e
        error_response(400, 'Bad Request', e.message)
      rescue StandardError => e
        @logger.error "REST API error: #{e.class} - #{e.message}"
        @logger.error e.backtrace.first(5).join("\n")
        error_response(500, 'Internal Server Error', e.message)
      end

      # Check if this router can handle the request path
      # @param path [String] Request path
      # @return [Boolean] true if path is handled by this router
      def handles?(path)
        path.start_with?('/api/v1/')
      end

      private

      # Handle generic tool endpoint: POST /api/v1/tools/{tool_name}
      def handle_generic_tool_call(request, method, path, client)
        return nil unless method == 'POST'

        # Extract tool name from path
        tool_name = path.sub('/api/v1/tools/', '')
        return nil if tool_name.empty? || tool_name.include?('/')

        # Parse request body for arguments
        body = parse_request_body(request)
        arguments = body['arguments'] || body['params'] || body

        @logger.info "REST API: Calling tool '#{tool_name}' via generic endpoint"
        call_tool(tool_name, arguments, client)
      end

      # Handle resource-based REST routes
      def handle_resource_route(request, method, path, client)
        # Parse path: /api/v1/{resource}[/{id}]
        parts = path.sub('/api/v1/', '').split('/')
        resource = parts[0]
        resource_id = parts[1]

        # Find matching route
        route_key = if resource_id
                      [method, resource, :id]
                    else
                      [method, resource, nil]
                    end

        tool_name = RESOURCE_ROUTES[route_key]
        return nil unless tool_name

        # Build arguments from query params and body
        arguments = build_arguments(request, resource, resource_id)

        @logger.info "REST API: Calling tool '#{tool_name}' for #{method} /#{resource}"
        call_tool(tool_name, arguments, client)
      end

      # Build tool arguments from request
      def build_arguments(request, resource, resource_id)
        arguments = {}

        # Add ID parameter if present
        if resource_id
          id_param = RESOURCE_ID_PARAM[resource] || :id
          # Try to convert to integer if it looks like a number
          arguments[id_param] = resource_id.match?(/\A\d+\z/) ? resource_id.to_i : resource_id
        end

        # Add query parameters (for GET requests)
        request.params.each do |key, value|
          sym_key = key.to_sym
          # Convert numeric strings to integers for common params
          arguments[sym_key] = if numeric_param?(sym_key) && value.to_s.match?(/\A\d+\z/)
                                 value.to_i
                               else
                                 value
                               end
        end

        # Add body parameters (for POST/PUT requests)
        if %w[POST PUT PATCH].include?(request.request_method)
          body = parse_request_body(request)
          # Merge body into arguments (body takes precedence)
          body.each do |key, value|
            arguments[key.to_sym] = value
          end
        end

        arguments
      end

      # Common numeric parameters
      NUMERIC_PARAMS = %i[
        id project_id issue_id user_id tracker_id status_id priority_id
        assigned_to_id author_id version_id membership_id time_entry_id
        limit offset parent_issue_id fixed_version_id activity_id
        group_id query_id custom_field_id
      ].freeze

      def numeric_param?(key)
        NUMERIC_PARAMS.include?(key)
      end

      # Parse JSON request body
      def parse_request_body(request)
        body = request.body.read
        request.body.rewind
        return {} if body.blank?

        JSON.parse(body)
      end

      # Call tool with per-request client
      def call_tool(tool_name, arguments, client)
        tool = @mcp_server.tools_by_name[tool_name]

        unless tool
          return {
            success: false,
            error: {
              type: 'ToolNotFoundError',
              message: "Tool '#{tool_name}' not found"
            }
          }
        end

        # If we have a per-request client, create a tool instance with it
        if client && client != RedmineMcpServer.redmine_client
          # Create new tool instance with the per-request client
          tool_class = tool.class
          tool_instance = tool_class.new(redmine_client: client, logger: @logger)
          tool_instance.call(arguments)
        else
          # Use existing tool with default client
          tool.call(arguments)
        end
      end

      # Format successful response
      def format_response(result)
        if result[:success]
          [
            200,
            { 'Content-Type' => 'application/json' },
            [JSON.generate(result[:data])]
          ]
        else
          error = result[:error] || {}
          status = case error[:type]
                   when 'NotFoundError' then 404
                   when 'AuthenticationError' then 401
                   when 'AuthorizationError' then 403
                   when 'ValidationError' then 422
                   when 'ToolNotFoundError' then 404
                   else 500
                   end

          [
            status,
            { 'Content-Type' => 'application/json' },
            [JSON.generate({
                             error: error[:type] || 'Error',
                             message: error[:message] || 'Unknown error',
                             status: error[:status]
                           })]
          ]
        end
      end

      # 404 Not Found response
      def not_found_response(path, method)
        [
          404,
          { 'Content-Type' => 'application/json' },
          [JSON.generate({
                           error: 'Not Found',
                           message: "No route matches #{method} #{path}",
                           path: path,
                           method: method
                         })]
        ]
      end

      # Generic error response
      def error_response(status, error, message)
        [
          status,
          { 'Content-Type' => 'application/json' },
          [JSON.generate({
                           error: error,
                           message: message
                         })]
        ]
      end
    end
  end
end
