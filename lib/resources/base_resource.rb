# frozen_string_literal: true

module RedmineMcpServer
  module Resources
    # Base class for all MCP resources
    class BaseResource
      attr_reader :redmine_client, :logger

      def initialize(redmine_client: nil, logger: nil)
        @redmine_client = redmine_client || RedmineMcpServer.redmine_client
        @logger = logger || RedmineMcpServer.logger
      end

      # Resource URI (must be overridden)
      # @return [String] The unique URI of this resource
      def uri
        raise NotImplementedError, "#{self.class} must implement #uri"
      end

      # Resource name (must be overridden)
      # @return [String] Human-readable name of the resource
      def name
        raise NotImplementedError, "#{self.class} must implement #name"
      end

      # Resource description (must be overridden)
      # @return [String] Description of what this resource provides
      def description
        raise NotImplementedError, "#{self.class} must implement #description"
      end

      # Resource MIME type
      # @return [String] MIME type of the resource
      def mime_type
        'application/json'
      end

      # Fetch resource contents (must be overridden)
      # @return [String] Resource contents
      def fetch
        raise NotImplementedError, "#{self.class} must implement #fetch"
      end

      # Convert resource to MCP format
      # @return [Hash] MCP resource definition
      def to_mcp
        {
          uri: uri,
          name: name,
          description: description,
          mimeType: mime_type
        }
      end

      # Read the resource (wrapper for fetch with error handling)
      # @return [Hash] Resource data with success/error status
      def read
        @logger.info "Reading resource: #{uri}"
        contents = fetch
        @logger.info "Resource #{uri} read successfully"
        {
          success: true,
          contents: contents,
          mimeType: mime_type
        }
      rescue AsyncRedmineClient::RedmineError => e
        @logger.error "Redmine API error reading #{uri}: #{e.message}"
        {
          success: false,
          error: {
            type: e.class.name.split('::').last,
            message: e.message,
            status: e.status
          }
        }
      rescue StandardError => e
        @logger.error "Error reading resource #{uri}: #{e.class} - #{e.message}"
        {
          success: false,
          error: {
            type: 'Error',
            message: e.message
          }
        }
      end

      # Read the resource with MCP protocol format response
      # @return [Hash] MCP-formatted result with contents array
      def read_for_mcp
        result = read

        if result[:success]
          # Success: return contents in MCP format
          {
            contents: [
              {
                uri: uri,
                mimeType: result[:mimeType],
                text: result[:contents]
              }
            ]
          }
        else
          # Error: return error in MCP format
          error_info = result[:error]
          error_message = if error_info[:status]
                            "#{error_info[:type]}: #{error_info[:message]} (HTTP #{error_info[:status]})"
                          else
                            "#{error_info[:type]}: #{error_info[:message]}"
                          end

          # For resources, we raise an error that the protocol adapter will catch
          raise StandardError, error_message
        end
      end
    end
  end
end
