# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Projects
      # Tool for creating a new project in Redmine
      class CreateProjectTool < BaseTool
        def name
          'create_project'
        end

        def description
          'Create a new project in Redmine. The project identifier must be unique and can only contain ' \
          'lowercase letters (a-z), numbers, dashes, and underscores. The identifier cannot be changed after creation.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: 'Project name (required)',
                minLength: 1
              },
              identifier: {
                type: 'string',
                description: 'Project identifier/slug (required). Must be unique, lowercase letters, numbers, dashes, and underscores only.',
                pattern: '^[a-z0-9-_]+$',
                minLength: 1
              },
              description: {
                type: 'string',
                description: 'Project description (optional)'
              },
              homepage: {
                type: 'string',
                description: 'Project homepage URL (optional)'
              },
              is_public: {
                type: 'boolean',
                description: 'Whether the project is public (default: true)',
                default: true
              },
              parent_id: {
                type: 'integer',
                description: 'Parent project ID for creating a subproject (optional)'
              },
              inherit_members: {
                type: 'boolean',
                description: 'Inherit members from parent project (default: false)',
                default: false
              },
              enabled_module_names: {
                type: 'array',
                description: 'List of module names to enable (e.g., issue_tracking, time_tracking, wiki, files, repository)',
                items: {
                  type: 'string',
                  enum: %w[issue_tracking time_tracking news documents files wiki
                           repository boards calendar gantt]
                }
              },
              tracker_ids: {
                type: 'array',
                description: 'List of tracker IDs to enable for this project',
                items: {
                  type: 'integer'
                }
              },
              custom_fields: {
                type: 'array',
                description: 'Custom field values',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    value: { type: %w[string number boolean array] }
                  }
                }
              }
            },
            required: %w[name identifier]
          }
        end

        def execute(params)
          validate_required_params(params, :name, :identifier)

          # Build project payload
          project_data = {
            name: params[:name],
            identifier: params[:identifier]
          }

          # Add optional fields
          project_data[:description] = params[:description] if params[:description]
          project_data[:homepage] = params[:homepage] if params[:homepage]
          project_data[:is_public] = params[:is_public] unless params[:is_public].nil?
          project_data[:parent_id] = params[:parent_id] if params[:parent_id]
          project_data[:inherit_members] = params[:inherit_members] unless params[:inherit_members].nil?
          project_data[:enabled_module_names] = params[:enabled_module_names] if params[:enabled_module_names]
          project_data[:tracker_ids] = params[:tracker_ids] if params[:tracker_ids]
          project_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]

          # Create project
          response = redmine_client.post('/projects', { project: project_data })

          response['project'] || response
        end
      end
    end
  end
end
