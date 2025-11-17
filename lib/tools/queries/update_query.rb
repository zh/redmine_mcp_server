# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Queries
      # Tool for updating an existing query (saved filter) in Redmine
      # Uses the Extended API plugin endpoint
      class UpdateQueryTool < BaseTool
        def name
          'update_query'
        end

        def description
          'Update an existing query in Redmine. Uses the Extended API plugin. ' \
            'Users can update their own private queries, users with manage_public_queries permission ' \
            'can update project public queries, and admins can update any query. ' \
            'Can modify name, filters, description, visibility, columns, and sorting.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              query_id: {
                type: 'integer',
                description: 'Query ID to update (required)'
              },
              name: {
                type: 'string',
                description: 'Query name'
              },
              visibility: {
                type: 'integer',
                description: 'Visibility level: 0=Private, 1=Roles, 2=Public',
                enum: [0, 1, 2]
              },
              project_id: {
                type: %w[string integer],
                description: 'Project ID or identifier (null for global query)'
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
            required: %w[query_id]
          }
        end

        def execute(params)
          validate_required_params(params, :query_id)

          # Build query update data (only include provided fields)
          query_data = {}
          query_data[:name] = params[:name] if params[:name]
          query_data[:visibility] = params[:visibility] if params.key?(:visibility)
          query_data[:project_id] = params[:project_id] if params.key?(:project_id)
          query_data[:filters] = params[:filters] if params[:filters]
          query_data[:column_names] = params[:column_names] if params[:column_names]
          query_data[:sort_criteria] = params[:sort_criteria] if params[:sort_criteria]
          query_data[:description] = params[:description] if params.key?(:description)
          query_data[:group_by] = params[:group_by] if params[:group_by]
          query_data[:role_ids] = params[:role_ids] if params[:role_ids]

          # Update query using Extended API
          redmine_client.put(
            "/extended_api/queries/#{params[:query_id]}",
            { query: query_data }
          )
        end
      end
    end
  end
end
