# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Memberships
      # Tool for listing project memberships from Redmine
      class ListMembershipsTool < BaseTool
        def name
          'list_memberships'
        end

        def description
          'List all memberships for a specific project. Returns users/groups assigned to the project with their roles.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: {
                type: 'integer',
                description: 'Project ID to list memberships for (required)'
              },
              limit: {
                type: 'integer',
                description: 'Maximum number of memberships to return (1-100, default: 25)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Number of memberships to skip for pagination (default: 0)',
                minimum: 0
              }
            },
            required: %w[project_id]
          }
        end

        def execute(params)
          validate_required_params(params, :project_id)

          # Build query parameters
          query_params = {}
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]

          # Fetch memberships
          response = redmine_client.get("/projects/#{params[:project_id]}/memberships", query_params)

          {
            memberships: response['memberships'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
