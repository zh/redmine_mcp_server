# frozen_string_literal: true

module RedmineMcpServer
  module Transports
    # STDIO Transport for MCP Protocol
    # Implements MCP protocol over stdin/stdout using JSON-RPC 2.0
    # - Reads newline-delimited JSON-RPC messages from stdin
    # - Writes newline-delimited JSON-RPC responses to stdout
    # - Logs to stderr (never stdout!)
    class StdioTransport
      def initialize(protocol_adapter, logger)
        @protocol_adapter = protocol_adapter
        @logger = logger
        @running = false

        # CRITICAL: Enable immediate flushing
        $stdout.sync = true
        $stderr.sync = true
      end

      # Start the STDIO transport loop
      # Reads from stdin until EOF or interrupt
      def start
        @running = true
        @logger.info 'STDIO transport starting...'

        setup_signal_handlers

        while @running && (line = read_line)
          process_line(line)
        end

        @logger.info 'STDIO transport shutting down (stdin closed)'
      rescue Interrupt
        @logger.info 'STDIO transport interrupted'
      rescue StandardError => e
        @logger.error "Fatal error in STDIO transport: #{e.message}"
        @logger.error e.backtrace.join("\n")
        raise
      ensure
        cleanup
      end

      # Stop the transport
      def stop
        @running = false
      end

      private

      # Read a single line from stdin
      # @return [String, nil] Line without newline, or nil if EOF
      def read_line
        line = $stdin.gets
        return nil if line.nil?

        line = line.strip
        return nil if line.empty?

        line
      rescue IOError => e
        @logger.error "IO error reading from stdin: #{e.message}"
        nil
      end

      # Process a single line of input
      # @param line [String] JSON-RPC message
      def process_line(line)
        # Parse JSON-RPC message
        message = JsonRpcHandler.parse_message(line)
        @logger.debug "Received request: #{message[:method]}" if message[:method]

        # Handle the message
        response = @protocol_adapter.handle_request(message)

        # Write response (if not a notification)
        write_response(response) if response
      rescue JsonRpcHandler::JsonRpcError => e
        # Protocol error - send JSON-RPC error response
        @logger.warn "JSON-RPC error: #{e.message}"
        error_response = e.to_response(extract_id_from_line(line))
        write_response(error_response)
      rescue StandardError => e
        # Unexpected error - send internal error response
        @logger.error "Unexpected error processing message: #{e.message}"
        @logger.error e.backtrace.join("\n")
        error_response = JsonRpcHandler.format_error(
          extract_id_from_line(line),
          JsonRpcHandler::INTERNAL_ERROR,
          'Internal error',
          e.message
        )
        write_response(error_response)
      end

      # Write a response to stdout
      # @param response [Hash] JSON-RPC response
      def write_response(response)
        # Convert to JSON (without newlines!)
        json = Oj.dump(response, mode: :compat)

        # CRITICAL: Verify no embedded newlines
        if json.include?("\n")
          @logger.error 'Response contains newline! This will break the protocol.'
          raise 'Response contains embedded newline'
        end

        # Write to stdout with newline delimiter
        $stdout.puts(json)
        @logger.debug "Sent response: #{response[:id]}"
      rescue StandardError => e
        @logger.error "Failed to write response: #{e.message}"
        raise
      end

      # Extract ID from malformed JSON for error response
      # @param line [String] JSON string (possibly malformed)
      # @return [Integer, String, nil] Request ID if found
      def extract_id_from_line(line)
        # Try to extract id field even from malformed JSON
        return nil unless line.include?('"id"')

        match = line.match(/"id"\s*:\s*([^,}\]]+)/)
        return nil unless match

        id_str = match[1].strip.gsub(/^"(.*)"$/, '\1')
        # Try to parse as number
        begin
          Integer(id_str)
        rescue StandardError
          id_str
        end
      rescue StandardError
        nil
      end

      # Setup signal handlers for graceful shutdown
      def setup_signal_handlers
        Signal.trap('INT') do
          @logger.info 'Received INT signal'
          stop
        end

        Signal.trap('TERM') do
          @logger.info 'Received TERM signal'
          stop
        end
      rescue ArgumentError => e
        # Signal trapping may not be available in all environments
        @logger.warn "Could not setup signal handlers: #{e.message}"
      end

      # Cleanup resources
      def cleanup
        @logger.info 'STDIO transport cleanup complete'
      end
    end
  end
end
