# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      class CreateIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'create_issue'
        end

        def description
          'Create a new issue in Redmine. Requires project_id, tracker_id, and subject at minimum.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: { type: %w[string integer], description: 'Project ID or identifier' },
              tracker_id: { type: 'integer', description: 'Tracker ID' },
              status_id: { type: 'integer', description: 'Status ID' },
              priority_id: { type: 'integer', description: 'Priority ID' },
              subject: { type: 'string', description: 'Issue subject/title', minLength: 1 },
              description: { type: 'string', description: 'Issue description' },
              assigned_to_id: { type: 'integer', description: 'Assignee user ID' },
              parent_issue_id: { type: 'integer', description: 'Parent issue ID' },
              estimated_hours: { type: 'number', description: 'Estimated hours' },
              done_ratio: { type: 'integer', description: 'Done ratio (0-100)', minimum: 0, maximum: 100 },
              custom_fields: { type: 'array', description: 'Custom field values' },
              watcher_user_ids: { type: 'array', items: { type: 'integer' }, description: 'Watcher user IDs' }
            },
            required: %w[project_id tracker_id subject]
          }
        end

        def execute(params)
          validate_required_params(params, :project_id, :tracker_id, :subject)

          issue_data = {
            project_id: params[:project_id],
            tracker_id: params[:tracker_id],
            subject: params[:subject]
          }

          # Add optional fields if provided
          issue_data[:status_id] = params[:status_id] if params[:status_id]
          issue_data[:priority_id] = params[:priority_id] if params[:priority_id]
          issue_data[:description] = params[:description] if params[:description]
          issue_data[:assigned_to_id] = params[:assigned_to_id] if params[:assigned_to_id]
          issue_data[:parent_issue_id] = params[:parent_issue_id] if params[:parent_issue_id]
          issue_data[:estimated_hours] = params[:estimated_hours] if params[:estimated_hours]
          issue_data[:done_ratio] = params[:done_ratio] if params[:done_ratio]
          issue_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]
          issue_data[:watcher_user_ids] = params[:watcher_user_ids] if params[:watcher_user_ids]

          response = redmine_client.post('/issues', { issue: issue_data })
          response['issue'] || response
        end
      end
    end
  end
end
