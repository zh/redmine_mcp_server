# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Memberships
      # Tool for deleting a membership from Redmine
      class DeleteMembershipTool < BaseTool
        def name
          'delete_membership'
        end

        def description
          'Remove a user or group from a project. Requires project management permissions.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              membership_id: {
                type: 'integer',
                description: 'Membership ID to delete (required)'
              }
            },
            required: %w[membership_id]
          }
        end

        def execute(params)
          validate_required_params(params, :membership_id)

          # Delete membership
          redmine_client.delete("/memberships/#{params[:membership_id]}")

          # Return success message
          { success: true, message: 'Membership deleted successfully' }
        end
      end
    end
  end
end
