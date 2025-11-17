# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Wiki
  class ListWikiPageVersionsTool < RedmineMcpServer::Tools::BaseTool
    def name = 'list_wiki_versions'
    def description = 'list_wiki_versions - Wiki page management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Wiki tools will be implemented in a future stage')
  end
end
