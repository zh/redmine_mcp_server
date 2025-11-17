# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer
  module Tools
    module Issues
      class GetIssueRelationsTool < RedmineMcpServer::Tools::BaseTool
        def name = 'get_issue_relations'
        def description = 'Get all relations for an issue (blocks, blocked by, relates to, etc.)'

        def input_schema
          { type: 'object', properties: { issue_id: { type: 'integer' } }, required: ['issue_id'] }
        end

        def execute(params)
          validate_required_params(params, :issue_id)

          issue_id = params[:issue_id]
          response = redmine_client.get("/issues/#{issue_id}/relations")

          {
            relations: response['relations'] || [],
            issue_id: issue_id
          }
        end
      end
    end
  end
end
