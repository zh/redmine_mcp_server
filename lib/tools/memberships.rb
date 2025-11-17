# frozen_string_literal: true

Dir[File.join(__dir__, 'memberships', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Memberships
  def self.register_all(mcp_server)
    [ListMembershipsTool.new, GetMembershipTool.new, CreateMembershipTool.new, DeleteMembershipTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
