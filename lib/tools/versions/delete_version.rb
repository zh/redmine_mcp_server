# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Versions
      # Tool for deleting a version from Redmine
      class DeleteVersionTool < BaseTool
        def name
          'delete_version'
        end

        def description
          'Delete a version/milestone from a project. Note: Version must not have any assigned issues.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              version_id: {
                type: 'integer',
                description: 'Version ID to delete (required)'
              }
            },
            required: %w[version_id]
          }
        end

        def execute(params)
          validate_required_params(params, :version_id)

          # Delete version
          redmine_client.delete("/versions/#{params[:version_id]}")

          # Return success message
          { success: true, message: 'Version deleted successfully' }
        end
      end
    end
  end
end
