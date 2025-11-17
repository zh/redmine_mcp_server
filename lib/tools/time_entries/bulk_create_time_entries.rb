# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for bulk creating multiple time entries in Redmine
      # Uses the Extended API plugin endpoint
      class BulkCreateTimeEntriesTool < BaseTool
        def name
          'bulk_create_time_entries'
        end

        def description
          'Create multiple time entries in a single request. Uses the Extended API plugin. ' \
            'Returns summary of created and failed entries.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              time_entries: {
                type: 'array',
                description: 'Array of time entries to create',
                items: {
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
                      description: 'Date the time was spent (YYYY-MM-DD)',
                      pattern: '^\\d{4}-\\d{2}-\\d{2}$'
                    },
                    hours: {
                      type: 'number',
                      description: 'Hours spent (required)',
                      minimum: 0.01
                    },
                    activity_id: {
                      type: 'integer',
                      description: 'Activity ID (required)'
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
              }
            },
            required: %w[time_entries]
          }
        end

        def execute(params)
          validate_required_params(params, :time_entries)

          # Validate that time_entries is an array
          raise ArgumentError, 'time_entries must be an array' unless params[:time_entries].is_a?(Array)

          # Validate that array is not empty
          raise ArgumentError, 'time_entries array cannot be empty' if params[:time_entries].empty?

          # Bulk create time entries using Extended API
          redmine_client.post('/extended_api/time_entries/bulk_create', { time_entries: params[:time_entries] })
        end
      end
    end
  end
end
