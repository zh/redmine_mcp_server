# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer
  module Tools
    module Issues
      class GetIssueJournalsTool < RedmineMcpServer::Tools::BaseTool
        def name = 'get_issue_journals'
        def description = 'Get the change history (journals) for an issue'

        def input_schema
          { type: 'object', properties: { issue_id: { type: 'integer' } }, required: ['issue_id'] }
        end

        def execute(params)
          validate_required_params(params, :issue_id)

          issue_id = params[:issue_id]
          response = redmine_client.get("/issues/#{issue_id}", { include: 'journals' })

          issue = response['issue'] || response
          {
            journals: issue['journals'] || [],
            issue_id: issue_id
          }
        end
      end
    end
  end
end
