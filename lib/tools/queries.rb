# frozen_string_literal: true

Dir[File.join(__dir__, 'queries', '*.rb')].each { |file| require file }

module RedmineMcpServer
  module Tools
    module Queries
      # Register all query tools with the MCP server
      def self.register_all(mcp_server)
        [
          ListQueriesTool.new,
          CreateQueryTool.new,
          UpdateQueryTool.new,
          DeleteQueryTool.new
        ].each do |tool|
          mcp_server.register_tool(tool)
        end
      end
    end
  end
end
