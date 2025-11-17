# frozen_string_literal: true

# Load batch tools
require_relative 'batch/batch_execute'

module RedmineMcpServer
  module Tools
    module Batch
      # Register all batch tools with the MCP server
      def self.register_all(mcp_server)
        [
          BatchExecuteTool.new
        ].each do |tool|
          mcp_server.register_tool(tool)
        end
      end
    end
  end
end
