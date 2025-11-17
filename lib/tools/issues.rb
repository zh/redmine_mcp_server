# frozen_string_literal: true

# Load all issue tools
Dir[File.join(__dir__, 'issues', '*.rb')].sort.each do |file| require file end

module RedmineMcpServer
  module Tools
    module Issues
      # Register all issue tools with the MCP server
      def self.register_all(mcp_server)
        [
          ListIssuesTool.new,
          GetIssueTool.new,
          CreateIssueTool.new,
          UpdateIssueTool.new,
          DeleteIssueTool.new,
          CopyIssueTool.new,
          MoveIssueTool.new,
          AddIssueWatcherTool.new,
          RemoveIssueWatcherTool.new,
          GetIssueRelationsTool.new,
          CreateIssueRelationTool.new,
          DeleteIssueRelationTool.new,
          GetIssueJournalsTool.new
        ].each do |tool|
          mcp_server.register_tool(tool)
        end
      end
    end
  end
end
