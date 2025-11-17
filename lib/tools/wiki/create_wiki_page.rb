# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Wiki
  class CreateWikiPageTool < RedmineMcpServer::Tools::BaseTool
    def name = 'create_wiki_page'
    def description = 'create_wiki_page - Wiki page management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Wiki tools will be implemented in a future stage')
  end
end
