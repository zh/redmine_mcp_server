# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Memberships
      # Tool for creating a new membership in Redmine
      class CreateMembershipTool < BaseTool
        def name
          'create_membership'
        end

        def description
          'Add a user or group to a project with specified roles. Requires project management permissions.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: {
                type: 'integer',
                description: 'Project ID to add the member to (required)'
              },
              user_id: {
                type: 'integer',
                description: 'User ID or Group ID to add to the project (required)'
              },
              role_ids: {
                type: 'array',
                description: 'Array of role IDs to assign to the member (required, at least one)',
                items: {
                  type: 'integer'
                },
                minItems: 1
              }
            },
            required: %w[project_id user_id role_ids]
          }
        end

        def execute(params)
          validate_required_params(params, :project_id, :user_id, :role_ids)

          # Build membership payload
          membership_data = {
            user_id: params[:user_id],
            role_ids: params[:role_ids]
          }

          # Create membership
          response = redmine_client.post(
            "/projects/#{params[:project_id]}/memberships",
            { membership: membership_data }
          )

          response['membership'] || response
        end
      end
    end
  end
end
