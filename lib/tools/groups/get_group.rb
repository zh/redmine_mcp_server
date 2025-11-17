# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Groups
      # Tool for getting a single group from Redmine
      class GetGroupTool < BaseTool
        def name
          'get_group'
        end

        def description
          'Get detailed information about a specific group by ID. Includes group metadata and optionally ' \
          'related data like users and memberships. Requires admin privileges.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Group ID'
              },
              include: {
                type: 'string',
                description: 'Comma-separated list of related data to include (users, memberships)',
                examples: ['users', 'memberships', 'users,memberships']
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          group_id = params[:id]
          query_params = {}
          query_params[:include] = params[:include] if params[:include]

          # Fetch group
          response = redmine_client.get("/groups/#{group_id}", query_params)

          response['group'] || response
        end
      end
    end
  end
end
