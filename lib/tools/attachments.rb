# frozen_string_literal: true

Dir[File.join(__dir__, 'attachments', '*.rb')].sort.each do |file| require file end
module RedmineMcpServer::Tools::Attachments
  def self.register_all(mcp_server)
    [UploadAttachmentTool.new, GetAttachmentTool.new, DeleteAttachmentTool.new].each { |tool| mcp_server.register_tool(tool) }
  end
end
