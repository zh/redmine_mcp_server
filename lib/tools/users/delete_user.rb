# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Users
      # Tool for deleting a user from Redmine
      class DeleteUserTool < BaseTool
        def name
          'delete_user'
        end

        def description
          'Delete a user from Redmine. This is a destructive operation that requires explicit confirmation. ' \
            'Requires admin privileges. User data will be permanently removed.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'User ID to delete'
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
            raise ArgumentError, 'User deletion requires explicit confirmation. Set confirm: true to proceed.'
          end

          user_id = params[:id]

          # Attempt to get user details before deletion (for logging/confirmation)
          begin
            user_info = redmine_client.get("/users/#{user_id}")
            user_login = user_info.dig('user', 'login') || user_id
            user_name = "#{user_info.dig('user', 'firstname')} #{user_info.dig('user', 'lastname')}".strip
            user_name = user_login if user_name.empty?
          rescue RedmineMcpServer::AsyncRedmineClient::NotFoundError
            raise ArgumentError, "User '#{user_id}' not found"
          end

          # Delete the user
          redmine_client.delete("/users/#{user_id}")

          # Return success message with details
          {
            success: true,
            message: "User '#{user_name}' (ID: #{user_id}, Login: #{user_login}) has been permanently deleted",
            deleted_user_id: user_id,
            deleted_user_login: user_login,
            deleted_user_name: user_name
          }
        end
      end
    end
  end
end
