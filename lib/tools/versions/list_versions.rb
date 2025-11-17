# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Versions
      # Tool for listing project versions from Redmine
      class ListVersionsTool < BaseTool
        def name
          'list_versions'
        end

        def description
          'List all versions/milestones for a specific project. Returns version details including name, status, dates, and completion.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: {
                type: 'integer',
                description: 'Project ID to list versions for (required)'
              }
            },
            required: %w[project_id]
          }
        end

        def execute(params)
          validate_required_params(params, :project_id)

          # Fetch versions for the project
          response = redmine_client.get("/projects/#{params[:project_id]}/versions")

          {
            versions: response['versions'] || []
          }
        end
      end
    end
  end
end
