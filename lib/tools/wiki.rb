# frozen_string_literal: true

Dir[File.join(__dir__, 'wiki', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Wiki
  def self.register_all(mcp_server)
    [ListWikiPagesTool.new, GetWikiPageTool.new, CreateWikiPageTool.new, UpdateWikiPageTool.new, DeleteWikiPageTool.new,
     ListWikiPageVersionsTool.new].each { |tool|
      mcp_server.register_tool(tool)
    }
  end
end
