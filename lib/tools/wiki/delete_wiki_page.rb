# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Wiki
  class DeleteWikiPageTool < RedmineMcpServer::Tools::BaseTool
    def name = 'delete_wiki_page'
    def description = 'delete_wiki_page - Wiki page management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Wiki tools will be implemented in a future stage')
  end
end
