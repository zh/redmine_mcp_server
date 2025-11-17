# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Projects
      # Tool for getting a single project from Redmine
      class GetProjectTool < BaseTool
        def name
          'get_project'
        end

        def description
          'Get detailed information about a specific project by ID or identifier. Includes project metadata, ' \
          'custom fields, and optionally related data like trackers, issue categories, enabled modules, and time entry activities.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: %w[string integer],
                description: 'Project ID (numeric) or identifier (string slug)'
              },
              include: {
                type: 'string',
                description: 'Comma-separated list of related data to include (trackers, issue_categories, ' \
                             'enabled_modules, time_entry_activities)',
                examples: ['trackers', 'enabled_modules', 'trackers,issue_categories,enabled_modules']
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          project_id = params[:id]
          query_params = {}
          query_params[:include] = params[:include] if params[:include]

          # Fetch project
          response = redmine_client.get("/projects/#{project_id}", query_params)

          response['project'] || response
        end
      end
    end
  end
end
