# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Queries
      # Tool for creating a new query (saved filter) in Redmine
      # Uses the Extended API plugin endpoint
      class CreateQueryTool < BaseTool
        def name
          'create_query'
        end

        def description
          'Create a new query in Redmine. Uses the Extended API plugin. ' \
            'Queries are saved filters/views for issues, time entries, projects, etc. ' \
            'Users can create private queries, users with manage_public_queries permission can ' \
            'create project public queries, and admins can create global public queries.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: 'Query name (required)',
                minLength: 1
              },
              type: {
                type: 'string',
                description: 'Query type (default: IssueQuery). Options: IssueQuery, ProjectQuery, ' \
                             'TimeEntryQuery',
                default: 'IssueQuery'
              },
              visibility: {
                type: 'integer',
                description: 'Visibility level: 0=Private (default), 1=Roles, 2=Public',
                enum: [0, 1, 2],
                default: 0
              },
              project_id: {
                type: %w[string integer],
                description: 'Project ID or identifier (leave empty for global query)'
              },
              filters: {
                type: 'object',
                description: 'Query filters as JSON object. Format: {"field": {"operator": "op", ' \
                             '"values": ["val1", "val2"]}}. Common operators: =, !=, >=, <=, ~, !~, o (open), ' \
                             'c (closed), t (today), w (week), m (month), <t+N (days from now), >t-N (days ago)'
              },
              column_names: {
                type: 'array',
                items: { type: 'string' },
                description: 'Array of column names to display (e.g., ["id", "subject", "status", "assigned_to"])'
              },
              sort_criteria: {
                type: 'array',
                items: {
                  type: 'array',
                  items: { type: 'string' }
                },
                description: 'Sort criteria as array of [field, direction] pairs ' \
                             '(e.g., [["due_date", "asc"], ["id", "desc"]])'
              },
              description: {
                type: 'string',
                description: 'Query description'
              },
              group_by: {
                type: 'string',
                description: 'Group results by field (e.g., "status", "assigned_to", "priority")'
              },
              role_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'Array of role IDs (required when visibility=1)'
              }
            },
            required: %w[name]
          }
        end

        def execute(params)
          validate_required_params(params, :name)

          # Build query data
          query_data = {
            name: params[:name]
          }

          # Add optional fields
          query_data[:type] = params[:type] if params[:type]
          query_data[:visibility] = params[:visibility] if params.key?(:visibility)
          query_data[:project_id] = params[:project_id] if params[:project_id]
          query_data[:filters] = params[:filters] if params[:filters]
          query_data[:column_names] = params[:column_names] if params[:column_names]
          query_data[:sort_criteria] = params[:sort_criteria] if params[:sort_criteria]
          query_data[:description] = params[:description] if params[:description]
          query_data[:group_by] = params[:group_by] if params[:group_by]
          query_data[:role_ids] = params[:role_ids] if params[:role_ids]

          # Create query using Extended API
          redmine_client.post('/extended_api/queries', { query: query_data })
        end
      end
    end
  end
end
