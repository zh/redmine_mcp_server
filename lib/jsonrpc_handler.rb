# frozen_string_literal: true

require 'oj'

module RedmineMcpServer
  # JSON-RPC 2.0 message handler for MCP protocol
  # Implements https://www.jsonrpc.org/specification
  class JsonRpcHandler
    # JSON-RPC error codes
    PARSE_ERROR = -32_700
    INVALID_REQUEST = -32_600
    METHOD_NOT_FOUND = -32_601
    INVALID_PARAMS = -32_602
    INTERNAL_ERROR = -32_603

    # Parse a JSON-RPC 2.0 message from a string
    # @param json_string [String] JSON-RPC message
    # @return [Hash] Parsed message with symbolized keys
    # @raise [JsonRpcError] if parsing fails
    def self.parse_message(json_string)
      message = Oj.load(json_string, symbol_keys: true)
      validate_message!(message)
      message
    rescue Oj::ParseError => e
      raise JsonRpcError.new(PARSE_ERROR, 'Parse error', e.message)
    end

    # Format a JSON-RPC 2.0 response
    # @param id [Integer, String, nil] Request ID
    # @param result [Hash] Result data
    # @return [Hash] JSON-RPC response
    def self.format_response(id, result)
      {
        jsonrpc: '2.0',
        id: id,
        result: result
      }
    end

    # Format a JSON-RPC 2.0 error response
    # @param id [Integer, String, nil] Request ID
    # @param code [Integer] Error code
    # @param message [String] Error message
    # @param data [Hash, nil] Optional error data
    # @return [Hash] JSON-RPC error response
    def self.format_error(id, code, message, data = nil)
      error = {
        jsonrpc: '2.0',
        id: id,
        error: {
          code: code,
          message: message
        }
      }
      error[:error][:data] = data if data
      error
    end

    # Format a JSON-RPC 2.0 notification (no response expected)
    # @param method [String] Notification method name
    # @param params [Hash] Notification parameters
    # @return [Hash] JSON-RPC notification
    def self.format_notification(method, params)
      {
        jsonrpc: '2.0',
        method: method,
        params: params
      }
    end

    # Check if a message is a notification (has no id)
    # @param message [Hash] Parsed JSON-RPC message
    # @return [Boolean]
    def self.notification?(message)
      !message.key?(:id)
    end

    # Validate JSON-RPC 2.0 message structure
    # @param message [Hash] Parsed message
    # @raise [JsonRpcError] if validation fails
    def self.validate_message!(message)
      raise JsonRpcError.new(INVALID_REQUEST, 'Missing jsonrpc field') unless message[:jsonrpc] == '2.0'
      raise JsonRpcError.new(INVALID_REQUEST, 'Missing method field') unless message[:method].is_a?(String)

      # id is optional (for notifications) but if present must be string, number, or null
      if message.key?(:id)
        id = message[:id]
        valid_id = id.nil? || id.is_a?(String) || id.is_a?(Integer) || id.is_a?(Float)
        raise JsonRpcError.new(INVALID_REQUEST, 'Invalid id field') unless valid_id
      end

      # params is optional but if present must be array or object
      return unless message.key?(:params)

      params = message[:params]
      valid_params = params.is_a?(Hash) || params.is_a?(Array)
      raise JsonRpcError.new(INVALID_REQUEST, 'Invalid params field') unless valid_params
    end

    # Custom error class for JSON-RPC errors
    class JsonRpcError < StandardError
      attr_reader :code, :data

      def initialize(code, message, data = nil)
        @code = code
        @data = data
        super(message)
      end

      def to_response(id)
        JsonRpcHandler.format_error(id, @code, message, @data)
      end
    end
  end
end
