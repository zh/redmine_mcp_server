# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Projects
      # Tool for listing projects from Redmine
      class ListProjectsTool < BaseTool
        # Map string status values to Redmine integer status codes
        STATUS_MAP = {
          'active' => 1,
          'archived' => 5,
          'closed' => 9
        }.freeze

        def name
          'list_projects'
        end

        def description
          'List all accessible projects from Redmine. Supports pagination, filtering, and including related data.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              limit: {
                type: 'integer',
                description: 'Maximum number of projects to return (1-100, default: 25)',
                minimum: 1,
                maximum: 100
              },
              offset: {
                type: 'integer',
                description: 'Number of projects to skip for pagination (default: 0)',
                minimum: 0
              },
              include: {
                type: 'string',
                description: 'Comma-separated list of related data to include (trackers, issue_categories, enabled_modules)',
                examples: ['trackers', 'issue_categories', 'trackers,enabled_modules']
              },
              status: {
                type: 'string',
                description: 'Filter by project status',
                enum: %w[active archived closed],
                default: 'active'
              }
            }
          }
        end

        def execute(params)
          # Build query parameters
          query_params = {}
          query_params[:limit] = params[:limit] if params[:limit]
          query_params[:offset] = params[:offset] if params[:offset]
          query_params[:include] = params[:include] if params[:include]

          # Convert string status to integer for Redmine API
          query_params[:status] = STATUS_MAP[params[:status]] || params[:status] if params[:status]

          # Fetch projects
          response = redmine_client.get('/projects', query_params)

          {
            projects: response['projects'] || [],
            total_count: response['total_count'] || 0,
            limit: response['limit'] || query_params[:limit] || 25,
            offset: response['offset'] || query_params[:offset] || 0
          }
        end
      end
    end
  end
end
