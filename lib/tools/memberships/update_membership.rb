# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Memberships
      # Tool for updating an existing membership in Redmine
      class UpdateMembershipTool < BaseTool
        def name
          'update_membership'
        end

        def description
          'Update the roles assigned to a project membership. Requires project management permissions.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              membership_id: {
                type: 'integer',
                description: 'Membership ID to update (required)'
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
            required: %w[membership_id role_ids]
          }
        end

        def execute(params)
          validate_required_params(params, :membership_id, :role_ids)

          # Build membership payload
          membership_data = {
            role_ids: params[:role_ids]
          }

          # Update membership
          redmine_client.put(
            "/memberships/#{params[:membership_id]}",
            { membership: membership_data }
          )

          # Return success message
          { success: true, message: 'Membership updated successfully' }
        end
      end
    end
  end
end
