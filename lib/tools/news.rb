# frozen_string_literal: true

Dir[File.join(__dir__, 'news', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::News
  def self.register_all(mcp_server)
    [ListNewsTool.new, GetNewsItemTool.new].each { |tool| mcp_server.register_tool(tool) }
  end
end
