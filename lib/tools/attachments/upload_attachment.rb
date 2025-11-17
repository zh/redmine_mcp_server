# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Attachments
  class UploadAttachmentTool < RedmineMcpServer::Tools::BaseTool
    def name = 'upload_attachment'
    def description = 'upload_attachment - Attachment management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Attachment tools will be implemented in a future stage')
  end
end
