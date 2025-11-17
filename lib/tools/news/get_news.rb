# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::News
  class GetNewsItemTool < RedmineMcpServer::Tools::BaseTool
    def name = 'get_news'
    def description = 'get_news - News management tool'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'News tools will be implemented in a future stage')
  end
end
