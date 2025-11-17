# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Attachments
  class DeleteAttachmentTool < RedmineMcpServer::Tools::BaseTool
    def name = 'delete_attachment'
    def description = 'delete_attachment - Attachment management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Attachment tools will be implemented in a future stage')
  end
end
