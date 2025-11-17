# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for creating a new time entry in Redmine
      class CreateTimeEntryTool < BaseTool
        def name
          'create_time_entry'
        end

        def description
          'Log time on an issue or project. Requires either issue_id or project_id, plus hours and activity.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              issue_id: {
                type: 'integer',
                description: 'Issue ID to log time against (required if project_id not provided)'
              },
              project_id: {
                type: 'integer',
                description: 'Project ID to log time against (required if issue_id not provided)'
              },
              spent_on: {
                type: 'string',
                description: 'Date the time was spent (YYYY-MM-DD, default: today)',
                pattern: '^\d{4}-\d{2}-\d{2}$'
              },
              hours: {
                type: 'number',
                description: 'Hours spent (required)',
                minimum: 0.01
              },
              activity_id: {
                type: 'integer',
                description: 'Activity ID (required, e.g., Development, Design, Testing)'
              },
              comments: {
                type: 'string',
                description: 'Comments/description of work done'
              },
              custom_field_values: {
                type: 'object',
                description: 'Custom field values as key-value pairs'
              }
            },
            required: %w[hours activity_id]
          }
        end

        def execute(params)
          validate_required_params(params, :hours, :activity_id)

          # Validate that either issue_id or project_id is provided
          raise ArgumentError, 'Either issue_id or project_id must be provided' unless params[:issue_id] || params[:project_id]

          # Build time entry data
          time_entry_data = {
            hours: params[:hours],
            activity_id: params[:activity_id]
          }

          time_entry_data[:issue_id] = params[:issue_id] if params[:issue_id]
          time_entry_data[:project_id] = params[:project_id] if params[:project_id]
          time_entry_data[:spent_on] = params[:spent_on] if params[:spent_on]
          time_entry_data[:comments] = params[:comments] if params[:comments]
          time_entry_data[:custom_field_values] = params[:custom_field_values] if params[:custom_field_values]

          # Create time entry
          response = redmine_client.post('/time_entries', { time_entry: time_entry_data })

          response['time_entry'] || response
        end
      end
    end
  end
end
