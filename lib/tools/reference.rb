# frozen_string_literal: true

Dir[File.join(__dir__, 'reference', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Reference
  def self.register_all(mcp_server)
    [ListTrackersTool.new, ListIssueStatusesTool.new, ListIssuePrioritiesTool.new, ListTimeEntryActivitiesTool.new,
     ListCustomFieldsTool.new, ListRolesTool.new, SearchTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
