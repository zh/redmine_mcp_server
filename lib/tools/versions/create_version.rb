# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Versions
      # Tool for creating a new version in Redmine
      class CreateVersionTool < BaseTool
        def name
          'create_version'
        end

        def description
          'Create a new version/milestone for a project. Versions are used to track releases, sprints, or milestones.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              project_id: {
                type: 'integer',
                description: 'Project ID to create the version in (required)'
              },
              name: {
                type: 'string',
                description: 'Version name (required)',
                minLength: 1
              },
              description: {
                type: 'string',
                description: 'Version description (optional)'
              },
              status: {
                type: 'string',
                description: 'Version status (default: open)',
                enum: %w[open locked closed],
                default: 'open'
              },
              sharing: {
                type: 'string',
                description: 'Version sharing mode (default: none)',
                enum: %w[none descendants hierarchy tree system],
                default: 'none'
              },
              due_date: {
                type: 'string',
                description: 'Due date in YYYY-MM-DD format (optional)',
                pattern: '^\d{4}-\d{2}-\d{2}$'
              },
              wiki_page_title: {
                type: 'string',
                description: 'Associated wiki page title (optional)'
              }
            },
            required: %w[project_id name]
          }
        end

        def execute(params)
          validate_required_params(params, :project_id, :name)

          # Build version payload
          version_data = {
            name: params[:name]
          }

          # Add optional fields
          version_data[:description] = params[:description] if params[:description]
          version_data[:status] = params[:status] if params[:status]
          version_data[:sharing] = params[:sharing] if params[:sharing]
          version_data[:due_date] = params[:due_date] if params[:due_date]
          version_data[:wiki_page_title] = params[:wiki_page_title] if params[:wiki_page_title]

          # Create version
          response = redmine_client.post(
            "/projects/#{params[:project_id]}/versions",
            { version: version_data }
          )

          response['version'] || response
        end
      end
    end
  end
end
