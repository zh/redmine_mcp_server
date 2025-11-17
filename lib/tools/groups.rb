# frozen_string_literal: true

Dir[File.join(__dir__, 'groups', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Groups
  def self.register_all(mcp_server)
    [ListGroupsTool.new, GetGroupTool.new, CreateGroupTool.new, UpdateGroupTool.new, DeleteGroupTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
