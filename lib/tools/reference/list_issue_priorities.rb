# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer::Tools::Reference
  class ListIssuePrioritiesTool < RedmineMcpServer::Tools::BaseTool
    def name = 'list_issue_priorities'
    def description = 'list_issue_priorities - Read-only reference data from Redmine'
    def input_schema = { type: 'object', properties: {} }
    def execute(_params) = raise(NotImplementedError, 'Reference tools will be implemented in a future stage')
  end
end
