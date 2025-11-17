# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      class DeleteIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'delete_issue'
        end

        def description
          'Delete an issue from Redmine'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: { type: 'integer', description: 'Issue ID' },
              confirm: {
                type: 'boolean',
                description: 'Must be true to confirm deletion (safety check)'
              }
            },
            required: %w[id confirm]
          }
        end

        def execute(params)
          validate_required_params(params, :id, :confirm)

          unless params[:confirm] == true
            raise ArgumentError, 'Issue deletion requires explicit confirmation. Set confirm: true to proceed.'
          end

          issue_id = params[:id]

          # Fetch issue details before deletion
          begin
            issue_info = redmine_client.get("/issues/#{issue_id}")
            issue_subject = issue_info.dig('issue', 'subject') || 'Unknown'
            project_name = issue_info.dig('issue', 'project', 'name') || 'Unknown'
          rescue RedmineMcpServer::AsyncRedmineClient::NotFoundError
            raise ArgumentError, "Issue '#{issue_id}' not found"
          end

          # Delete the issue
          redmine_client.delete("/issues/#{issue_id}")

          {
            success: true,
            message: "Issue ##{issue_id} '#{issue_subject}' from project '#{project_name}' has been permanently deleted",
            deleted_issue_id: issue_id,
            deleted_issue_subject: issue_subject,
            deleted_project_name: project_name
          }
        end
      end
    end
  end
end
