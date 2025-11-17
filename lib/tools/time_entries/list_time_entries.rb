# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module TimeEntries
      # Tool for listing time entries from Redmine
      class ListTimeEntriesTool < BaseTool
        def name
          'list_time_entries'
        end

        def description
          'List time entries from Redmine with filtering by user, project, issue, or date range. ' \
          'Supports pagination.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              user_id: {
                type: 'integer',
                description: 'Filter by user ID'
              },
              project_id: {
                type: 'integer',
                description: 'Filter by project ID'
              },
              issue_id: {
                type: 'integer',
                description: 'Filter by issue ID'
              },
              spent_on: {
                type: 'string',
                description: 'Filter by specific date (YYYY-MM-DD)'
              },
              from: {
                type: 'string',
                description: 'Filter entries from this date (YYYY-MM-DD)'
              },
              to: {
                type: 'string',
                description: 'Filter entries until this date (YYYY-MM-DD)'
              },
              limit: {
                type: 'integer',
                description: 'Maximum number to return (1-100, default: 25)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Pagination offset (default: 0)',
                minimum: 0
              }
            }
          }
        end

        def execute(params)
          # Build query parameters
          query_params = {}
          query_params[:user_id] = params[:user_id] if params[:user_id]
          query_params[:project_id] = params[:project_id] if params[:project_id]
          query_params[:issue_id] = params[:issue_id] if params[:issue_id]
          query_params[:spent_on] = params[:spent_on] if params[:spent_on]
          query_params[:from] = params[:from] if params[:from]
          query_params[:to] = params[:to] if params[:to]
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]

          # Fetch time entries
          response = redmine_client.get('/time_entries', query_params)

          {
            time_entries: response['time_entries'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
