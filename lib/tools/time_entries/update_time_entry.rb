# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for updating an existing time entry in Redmine
      class UpdateTimeEntryTool < BaseTool
        def name
          'update_time_entry'
        end

        def description
          'Update an existing time entry. Can modify hours, date, activity, comments, or custom fields.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              time_entry_id: {
                type: 'integer',
                description: 'Time entry ID to update (required)'
              },
              issue_id: {
                type: 'integer',
                description: 'Issue ID to log time against'
              },
              project_id: {
                type: 'integer',
                description: 'Project ID to log time against'
              },
              spent_on: {
                type: 'string',
                description: 'Date the time was spent (YYYY-MM-DD)',
                pattern: '^\d{4}-\d{2}-\d{2}$'
              },
              hours: {
                type: 'number',
                description: 'Hours spent',
                minimum: 0.01
              },
              activity_id: {
                type: 'integer',
                description: 'Activity ID'
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
            required: %w[time_entry_id]
          }
        end

        def execute(params)
          validate_required_params(params, :time_entry_id)

          # Build time entry update data (only include provided fields)
          time_entry_data = {}
          time_entry_data[:issue_id] = params[:issue_id] if params[:issue_id]
          time_entry_data[:project_id] = params[:project_id] if params[:project_id]
          time_entry_data[:spent_on] = params[:spent_on] if params[:spent_on]
          time_entry_data[:hours] = params[:hours] if params[:hours]
          time_entry_data[:activity_id] = params[:activity_id] if params[:activity_id]
          time_entry_data[:comments] = params[:comments] if params[:comments]
          time_entry_data[:custom_field_values] = params[:custom_field_values] if params[:custom_field_values]

          # Update time entry
          redmine_client.put(
            "/time_entries/#{params[:time_entry_id]}",
            { time_entry: time_entry_data }
          )

          # Return success message
          { success: true, message: 'Time entry updated successfully' }
        end
      end
    end
  end
end
