# frozen_string_literal: true

require_relative '../base_tool'
module RedmineMcpServer
  module Tools
    module Issues
      class AddIssueWatcherTool < RedmineMcpServer::Tools::BaseTool
        def name = 'add_issue_watcher'
        def description = 'Add a watcher to an issue'

        def input_schema
          { type: 'object', properties: { issue_id: { type: 'integer' }, user_id: { type: 'integer' } },
            required: %w[issue_id user_id] }
        end

        def execute(params)
          validate_required_params(params, :issue_id, :user_id)

          issue_id = params[:issue_id]
          user_id = params[:user_id]

          # Add watcher
          redmine_client.post("/issues/#{issue_id}/watchers", { user_id: user_id })

          {
            success: true,
            message: "User #{user_id} added as watcher to issue #{issue_id}",
            issue_id: issue_id,
            user_id: user_id
          }
        end
      end
    end
  end
end
