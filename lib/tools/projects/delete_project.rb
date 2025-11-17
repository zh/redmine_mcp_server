# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Projects
      # Tool for deleting a project from Redmine
      class DeleteProjectTool < BaseTool
        def name
          'delete_project'
        end

        def description
          'Delete a project from Redmine. WARNING: This action is irreversible and will permanently delete the ' \
            'project and all associated data (issues, wiki pages, files, time entries, etc.). Use with extreme caution.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: %w[string integer],
                description: 'Project ID (numeric) or identifier (string slug) to delete'
              },
              confirm: {
                type: 'boolean',
                description: 'Must be set to true to confirm deletion (safety check)',
                const: true
              }
            },
            required: %w[id confirm]
          }
        end

        def execute(params)
          validate_required_params(params, :id, :confirm)

          # Safety check - require explicit confirmation
          unless params[:confirm] == true
            raise ArgumentError, 'Project deletion requires explicit confirmation. Set confirm: true to proceed.'
          end

          project_id = params[:id]

          # Attempt to get project details before deletion (for logging/confirmation)
          begin
            project_info = redmine_client.get("/projects/#{project_id}")
            project_name = project_info.dig('project', 'name') || project_id
          rescue RedmineMcpServer::AsyncRedmineClient::NotFoundError
            raise ArgumentError, "Project '#{project_id}' not found"
          end

          # Delete the project
          redmine_client.delete("/projects/#{project_id}")

          # Return success message with details
          {
            success: true,
            message: "Project '#{project_name}' (ID: #{project_id}) has been permanently deleted",
            deleted_project_id: project_id,
            deleted_project_name: project_name
          }
        end
      end
    end
  end
end
