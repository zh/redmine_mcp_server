# frozen_string_literal: true

module RedmineMcpServer
  module Tools
    # Base class for all MCP tools
    class BaseTool
      attr_reader :redmine_client, :logger, :metrics_collector

      def initialize(redmine_client: nil, logger: nil, metrics_collector: nil)
        @redmine_client = redmine_client || RedmineMcpServer.redmine_client
        @logger = logger || RedmineMcpServer.logger
        @metrics_collector = metrics_collector
      end

      # Tool name (must be overridden)
      # @return [String] The unique name of this tool
      def name
        raise NotImplementedError, "#{self.class} must implement #name"
      end

      # Tool description (must be overridden)
      # @return [String] Human-readable description of what this tool does
      def description
        raise NotImplementedError, "#{self.class} must implement #description"
      end

      # Input schema (must be overridden)
      # @return [Hash] JSON Schema defining the tool's input parameters
      def input_schema
        raise NotImplementedError, "#{self.class} must implement #input_schema"
      end

      # Execute the tool (must be overridden)
      # @param params [Hash] Input parameters matching the input_schema
      # @return [Hash] Tool execution result
      def execute(params)
        raise NotImplementedError, "#{self.class} must implement #execute"
      end

      # Convert tool to MCP format
      # @return [Hash] MCP tool definition
      def to_mcp
        {
          name: name,
          description: description,
          inputSchema: input_schema
        }
      end

      # Call the tool (wrapper for execute with logging and error handling)
      # @param params [Hash] Input parameters
      # @return [Hash] Execution result with success/error status
      def call(params = {})
        start_time = Time.now
        @logger.info "Executing tool: #{name} with params: #{sanitize_params_for_logging(params).inspect}"

        result = execute(params)
        duration = Time.now - start_time

        # Record successful execution metrics
        record_metrics(duration: duration, success: true) if @metrics_collector

        @logger.info "Tool #{name} completed successfully"
        { success: true, data: result }
      rescue AsyncRedmineClient::RedmineError => e
        duration = Time.now - start_time
        error_type = e.class.name.split('::').last

        # Record failed execution metrics
        record_metrics(duration: duration, success: false, error_type: error_type) if @metrics_collector

        @logger.error "Redmine API error in #{name}: #{e.message}"
        {
          success: false,
          error: {
            type: error_type,
            message: e.message,
            status: e.status
          }
        }
      rescue StandardError => e
        duration = Time.now - start_time
        error_type = 'Error'

        # Record failed execution metrics
        record_metrics(duration: duration, success: false, error_type: error_type) if @metrics_collector

        @logger.error "Error executing #{name}: #{e.class} - #{e.message}"
        @logger.error e.backtrace.first(5).join("\n") if @logger.debug?
        {
          success: false,
          error: {
            type: error_type,
            message: e.message
          }
        }
      end

      # Call the tool with MCP protocol format response
      # @param params [Hash] Input parameters
      # @return [Hash] MCP-formatted result with content array
      def call_for_mcp(params = {})
        result = call(params)

        if result[:success]
          # Success: return data as JSON text content
          {
            content: [
              {
                type: 'text',
                text: Oj.dump(result[:data], mode: :compat)
              }
            ],
            isError: false
          }
        else
          # Error: return error message as text content
          error_info = result[:error]
          error_message = if error_info[:status]
                            "#{error_info[:type]}: #{error_info[:message]} (HTTP #{error_info[:status]})"
                          else
                            "#{error_info[:type]}: #{error_info[:message]}"
                          end

          {
            content: [
              {
                type: 'text',
                text: error_message
              }
            ],
            isError: true
          }
        end
      end

      protected

      # Validate required parameters
      # @param params [Hash] Input parameters
      # @param required [Array<Symbol>] Required parameter keys
      # @raise [ArgumentError] if any required parameters are missing
      def validate_required_params(params, *required)
        missing = required.select { |key| params[key].nil? }
        return if missing.empty?

        raise ArgumentError, "Missing required parameters: #{missing.join(', ')}"
      end

      # Extract pagination parameters
      # @param params [Hash] Input parameters
      # @return [Hash] Pagination parameters {limit:, offset:}
      def extract_pagination(params)
        {
          limit: params[:limit]&.to_i || 25,
          offset: params[:offset].to_i
        }
      end

      # Sanitize parameters for logging (redact sensitive fields)
      # @param params [Hash] Parameters to sanitize
      # @return [Hash] Sanitized parameters
      def sanitize_params_for_logging(params)
        return params unless params.is_a?(Hash)

        params.each_with_object({}) do |(key, value), result|
          result[key] = sensitive_key?(key) ? '[REDACTED]' : value
        end
      end

      # Check if a parameter key should be redacted
      # @param key [String, Symbol] Parameter key
      # @return [Boolean] true if key contains sensitive data
      def sensitive_key?(key)
        key_str = key.to_s.downcase
        key_str.match?(/password|secret|token|api[_-]?key|auth|credential/)
      end

      # Record metrics for tool execution
      # @param duration [Float] Execution duration in seconds
      # @param success [Boolean] Whether execution succeeded
      # @param error_type [String, nil] Type of error if failed
      def record_metrics(duration:, success:, error_type: nil)
        @metrics_collector.record_tool(name, duration, success, error_type: error_type)
      end
    end
  end
end
