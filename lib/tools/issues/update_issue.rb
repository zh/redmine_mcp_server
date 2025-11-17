# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      class UpdateIssueTool < RedmineMcpServer::Tools::BaseTool
        def name
          'update_issue'
        end

        def description
          'Update an existing issue in Redmine'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: { type: 'integer', description: 'Issue ID' },
              project_id: { type: %w[string integer], description: 'Move issue to this project ID' },
              tracker_id: { type: 'integer', description: 'Tracker ID' },
              status_id: { type: 'integer', description: 'Status ID' },
              priority_id: { type: 'integer', description: 'Priority ID' },
              subject: { type: 'string', description: 'Issue subject/title' },
              description: { type: 'string', description: 'Issue description' },
              assigned_to_id: { type: 'integer', description: 'Assignee user or group ID' },
              start_date: { type: 'string', description: 'Start date (YYYY-MM-DD)' },
              due_date: { type: 'string', description: 'Due date (YYYY-MM-DD)' },
              parent_issue_id: { type: 'integer', description: 'Parent issue ID' },
              estimated_hours: { type: 'number', description: 'Estimated hours' },
              done_ratio: { type: 'integer', description: 'Done ratio (0-100)', minimum: 0, maximum: 100 },
              fixed_version_id: { type: 'integer', description: 'Target version ID' },
              notes: { type: 'string', description: 'Add comment/note to issue' },
              private_notes: { type: 'boolean', description: 'Make notes private' },
              custom_fields: { type: 'array', description: 'Custom field values' }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          issue_id = params[:id]
          issue_data = {}

          # Build update data from provided fields
          issue_data[:project_id] = params[:project_id] if params[:project_id]
          issue_data[:tracker_id] = params[:tracker_id] if params[:tracker_id]
          issue_data[:status_id] = params[:status_id] if params[:status_id]
          issue_data[:priority_id] = params[:priority_id] if params[:priority_id]
          issue_data[:subject] = params[:subject] if params[:subject]
          issue_data[:description] = params[:description] if params[:description]
          issue_data[:assigned_to_id] = params[:assigned_to_id] if params[:assigned_to_id]
          issue_data[:start_date] = params[:start_date] if params[:start_date]
          issue_data[:due_date] = params[:due_date] if params[:due_date]
          issue_data[:parent_issue_id] = params[:parent_issue_id] if params[:parent_issue_id]
          issue_data[:estimated_hours] = params[:estimated_hours] if params[:estimated_hours]
          issue_data[:done_ratio] = params[:done_ratio] if params[:done_ratio]
          issue_data[:fixed_version_id] = params[:fixed_version_id] if params[:fixed_version_id]
          issue_data[:notes] = params[:notes] if params[:notes]
          issue_data[:private_notes] = params[:private_notes] unless params[:private_notes].nil?
          issue_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]

          raise ArgumentError, 'At least one field must be provided to update' if issue_data.empty?

          response = redmine_client.put("/issues/#{issue_id}", { issue: issue_data })

          # Fetch updated issue if response is empty
          if response.empty?
            get_response = redmine_client.get("/issues/#{issue_id}")
            get_response['issue'] || get_response
          else
            response['issue'] || response
          end
        end
      end
    end
  end
end
