# frozen_string_literal: true

Dir[File.join(__dir__, 'versions', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Versions
  def self.register_all(mcp_server)
    [ListVersionsTool.new, GetVersionTool.new, CreateVersionTool.new, UpdateVersionTool.new, DeleteVersionTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
