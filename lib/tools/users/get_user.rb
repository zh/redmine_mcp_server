# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Users
      # Tool for getting a single user from Redmine
      class GetUserTool < BaseTool
        def name
          'get_user'
        end

        def description
          'Get detailed information about a specific user by ID or get the current authenticated user. ' \
          'Use "current" as ID to get information about the API user. Includes user metadata, custom fields, ' \
          'and optionally related data like memberships and groups.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: %w[string integer],
                description: 'User ID (numeric) or "current" for the authenticated API user'
              },
              include: {
                type: 'string',
                description: 'Comma-separated list of related data to include (memberships, groups)',
                examples: ['memberships', 'groups', 'memberships,groups']
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          user_id = params[:id]
          query_params = {}
          query_params[:include] = params[:include] if params[:include]

          # Fetch user
          response = redmine_client.get("/users/#{user_id}", query_params)

          response['user'] || response
        end
      end
    end
  end
end
