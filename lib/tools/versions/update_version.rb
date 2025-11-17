# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Versions
      # Tool for updating an existing version in Redmine
      class UpdateVersionTool < BaseTool
        def name
          'update_version'
        end

        def description
          'Update an existing version/milestone. Can update name, description, status, dates, and other properties.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              version_id: {
                type: 'integer',
                description: 'Version ID to update (required)'
              },
              name: {
                type: 'string',
                description: 'Version name (optional)',
                minLength: 1
              },
              description: {
                type: 'string',
                description: 'Version description (optional)'
              },
              status: {
                type: 'string',
                description: 'Version status (optional)',
                enum: %w[open locked closed]
              },
              sharing: {
                type: 'string',
                description: 'Version sharing mode (optional)',
                enum: %w[none descendants hierarchy tree system]
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
            required: %w[version_id]
          }
        end

        def execute(params)
          validate_required_params(params, :version_id)

          # Build version payload with only provided fields
          version_data = {}
          version_data[:name] = params[:name] if params[:name]
          version_data[:description] = params[:description] if params[:description]
          version_data[:status] = params[:status] if params[:status]
          version_data[:sharing] = params[:sharing] if params[:sharing]
          version_data[:due_date] = params[:due_date] if params[:due_date]
          version_data[:wiki_page_title] = params[:wiki_page_title] if params[:wiki_page_title]

          # Update version
          redmine_client.put(
            "/versions/#{params[:version_id]}",
            { version: version_data }
          )

          # Return success message
          { success: true, message: 'Version updated successfully' }
        end
      end
    end
  end
end
