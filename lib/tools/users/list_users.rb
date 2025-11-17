# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Users
      # Tool for listing users from Redmine
      class ListUsersTool < BaseTool
        def name
          'list_users'
        end

        def description
          'List all users from Redmine. Supports pagination and filtering by status, name, or group. ' \
          'Requires admin privileges to see all users.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              limit: {
                type: 'integer',
                description: 'Maximum number of users to return (1-100, default: 25)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Number of users to skip for pagination (default: 0)',
                minimum: 0
              },
              status: {
                type: 'integer',
                description: 'Filter by user status: 0=anonymous, 1=active (default), 2=registered, 3=locked',
                enum: [0, 1, 2, 3],
                default: 1
              },
              name: {
                type: 'string',
                description: 'Filter by login, firstname, lastname, or mail (partial match)'
              },
              group_id: {
                type: 'integer',
                description: 'Filter users by group membership (group ID)'
              }
            }
          }
        end

        def execute(params)
          # Build query parameters
          query_params = {}
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]
          query_params[:status] = params[:status] if params[:status]
          query_params[:name] = params[:name] if params[:name]
          query_params[:group_id] = params[:group_id] if params[:group_id]

          # Fetch users
          response = redmine_client.get('/users', query_params)

          {
            users: response['users'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
