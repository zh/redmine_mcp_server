# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Issues
      # Tool for listing issues from Redmine
      class ListIssuesTool < RedmineMcpServer::Tools::BaseTool
        def name
          'list_issues'
        end

        def description
          'List issues from Redmine with filtering, sorting, and pagination. Supports saved query ' \
            'execution via query_id, custom filtering, status filtering, assignee filtering, and more.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              query_id: {
                type: 'integer',
                description: 'Apply a saved query by ID (executes the filters, sorting, and columns ' \
                             'defined in the query)'
              },
              project_id: {
                type: %w[string integer],
                description: 'Filter by project ID or identifier'
              },
              tracker_id: {
                type: 'integer',
                description: 'Filter by tracker ID'
              },
              status_id: {
                type: %w[string integer],
                description: 'Filter by status ID (use "open" or "closed" or "*" for all)'
              },
              assigned_to_id: {
                type: 'integer',
                description: 'Filter by assignee user ID'
              },
              limit: {
                type: 'integer',
                description: 'Maximum number of issues to return (1-100)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Number of issues to skip for pagination',
                minimum: 0
              },
              sort: {
                type: 'string',
                description: 'Sort field with optional :desc suffix (e.g., "updated_on:desc")'
              },
              include: {
                type: 'string',
                description: 'Comma-separated list: attachments,relations,journals,watchers'
              }
            }
          }
        end

        def execute(params)
          # Build query parameters
          query_params = {}
          query_params[:query_id] = params[:query_id] if params[:query_id]
          query_params[:project_id] = params[:project_id] if params[:project_id]
          query_params[:tracker_id] = params[:tracker_id] if params[:tracker_id]
          query_params[:status_id] = params[:status_id] if params[:status_id]
          query_params[:assigned_to_id] = params[:assigned_to_id] if params[:assigned_to_id]
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]
          query_params[:sort] = params[:sort] if params[:sort]
          query_params[:include] = params[:include] if params[:include]

          # Fetch issues
          response = redmine_client.get('/issues', query_params)

          {
            issues: response['issues'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
