# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for deleting a time entry from Redmine
      class DeleteTimeEntryTool < BaseTool
        def name
          'delete_time_entry'
        end

        def description
          'Delete a time entry. Requires appropriate permissions to delete the time entry.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              time_entry_id: {
                type: 'integer',
                description: 'Time entry ID to delete (required)'
              }
            },
            required: %w[time_entry_id]
          }
        end

        def execute(params)
          validate_required_params(params, :time_entry_id)

          # Delete time entry
          redmine_client.delete("/time_entries/#{params[:time_entry_id]}")

          # Return success message
          { success: true, message: 'Time entry deleted successfully' }
        end
      end
    end
  end
end
