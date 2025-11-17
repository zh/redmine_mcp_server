# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Queries
      # Tool for deleting a query (saved filter) from Redmine
      # Uses the Extended API plugin endpoint
      class DeleteQueryTool < BaseTool
        def name
          'delete_query'
        end

        def description
          'Delete a query from Redmine. Uses the Extended API plugin. ' \
            'Users can delete their own private queries, users with manage_public_queries permission ' \
            'can delete project public queries, and admins can delete any query.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              query_id: {
                type: 'integer',
                description: 'Query ID to delete (required)'
              }
            },
            required: %w[query_id]
          }
        end

        def execute(params)
          validate_required_params(params, :query_id)

          # Delete query using Extended API
          redmine_client.delete("/extended_api/queries/#{params[:query_id]}")

          # Return success message
          { success: true, message: 'Query deleted successfully' }
        end
      end
    end
  end
end
