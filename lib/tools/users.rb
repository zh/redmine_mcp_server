# frozen_string_literal: true

Dir[File.join(__dir__, 'users', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Users
  def self.register_all(mcp_server)
    [ListUsersTool.new, GetUserTool.new, CreateUserTool.new, UpdateUserTool.new, DeleteUserTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
