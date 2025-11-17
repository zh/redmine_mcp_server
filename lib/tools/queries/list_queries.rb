# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Queries
      # Tool for listing queries (saved filters) from Redmine
      class ListQueriesTool < BaseTool
        def name
          'list_queries'
        end

        def description
          'List all accessible queries from Redmine. Queries are saved filters/views for issues, ' \
            'time entries, projects, etc. Supports pagination and filtering by project.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: {
                type: %w[string integer],
                description: 'Filter by project ID or identifier'
              },
              limit: {
                type: 'integer',
                description: 'Maximum number of queries to return (1-100, default: 25)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Number of queries to skip for pagination (default: 0)',
                minimum: 0
              }
            }
          }
        end

        def execute(params)
          # Build query parameters
          query_params = {}
          query_params[:project_id] = params[:project_id] if params[:project_id]
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]

          # Fetch queries from Redmine core API
          response = redmine_client.get('/queries', query_params)

          {
            queries: response['queries'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
