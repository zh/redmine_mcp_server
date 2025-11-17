# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for getting a specific time entry from Redmine
      class GetTimeEntryTool < BaseTool
        def name
          'get_time_entry'
        end

        def description
          'Get detailed information about a specific time entry including project, issue, user, activity, and custom field values.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              time_entry_id: {
                type: 'integer',
                description: 'Time entry ID to retrieve (required)'
              }
            },
            required: %w[time_entry_id]
          }
        end

        def execute(params)
          validate_required_params(params, :time_entry_id)

          # Fetch time entry
          response = redmine_client.get("/time_entries/#{params[:time_entry_id]}")

          response['time_entry'] || response
        end
      end
    end
  end
end
