# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Groups
      # Tool for deleting a group from Redmine
      class DeleteGroupTool < BaseTool
        def name
          'delete_group'
        end

        def description
          'Delete a group from Redmine. This is a destructive operation that requires explicit confirmation. ' \
            'Requires admin privileges. Group data will be permanently removed.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Group ID to delete'
              },
              confirm: {
                type: 'boolean',
                description: 'REQUIRED: Must be exactly true to confirm deletion. This safety check prevents accidental deletions.'
              }
            },
            required: %w[id confirm]
          }
        end

        def execute(params)
          validate_required_params(params, :id, :confirm)

          # Safety check - require explicit confirmation
          unless params[:confirm] == true
            raise ArgumentError, 'Group deletion requires explicit confirmation. Set confirm: true to proceed.'
          end

          group_id = params[:id]

          # Attempt to get group details before deletion (for logging/confirmation)
          begin
            group_info = redmine_client.get("/groups/#{group_id}")
            group_name = group_info.dig('group', 'name') || group_id
          rescue RedmineMcpServer::AsyncRedmineClient::NotFoundError
            raise ArgumentError, "Group '#{group_id}' not found"
          end

          # Delete the group
          redmine_client.delete("/groups/#{group_id}")

          # Return success message with details
          {
            success: true,
            message: "Group '#{group_name}' (ID: #{group_id}) has been permanently deleted",
            deleted_group_id: group_id,
            deleted_group_name: group_name
          }
        end
      end
    end
  end
end
