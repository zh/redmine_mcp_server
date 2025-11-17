# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Projects
      # Tool for updating an existing project in Redmine
      class UpdateProjectTool < BaseTool
        def name
          'update_project'
        end

        def description
          'Update an existing project in Redmine. Only provided fields will be updated. Note that the project ' \
          'identifier cannot be changed after creation.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: %w[string integer],
                description: 'Project ID (numeric) or identifier (string slug) - required'
              },
              name: {
                type: 'string',
                description: 'New project name',
                minLength: 1
              },
              description: {
                type: 'string',
                description: 'New project description'
              },
              homepage: {
                type: 'string',
                description: 'New project homepage URL'
              },
              is_public: {
                type: 'boolean',
                description: 'Whether the project should be public'
              },
              parent_id: {
                type: %w[integer null],
                description: 'New parent project ID (set to null to remove parent)'
              },
              inherit_members: {
                type: 'boolean',
                description: 'Whether to inherit members from parent project'
              },
              enabled_module_names: {
                type: 'array',
                description: 'List of module names to enable (replaces existing modules)',
                items: {
                  type: 'string',
                  enum: %w[issue_tracking time_tracking news documents files wiki
                           repository boards calendar gantt]
                }
              },
              tracker_ids: {
                type: 'array',
                description: 'List of tracker IDs to enable (replaces existing trackers)',
                items: {
                  type: 'integer'
                }
              },
              custom_fields: {
                type: 'array',
                description: 'Custom field values to update',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    value: { type: %w[string number boolean array] }
                  }
                }
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          project_id = params[:id]

          # Build project update payload (only include fields that are provided)
          project_data = {}

          project_data[:name] = params[:name] if params[:name]
          project_data[:description] = params[:description] if params.key?(:description)
          project_data[:homepage] = params[:homepage] if params.key?(:homepage)
          project_data[:is_public] = params[:is_public] unless params[:is_public].nil?
          project_data[:parent_id] = params[:parent_id] if params.key?(:parent_id)
          project_data[:inherit_members] = params[:inherit_members] unless params[:inherit_members].nil?
          project_data[:enabled_module_names] = params[:enabled_module_names] if params[:enabled_module_names]
          project_data[:tracker_ids] = params[:tracker_ids] if params[:tracker_ids]
          project_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]

          # Ensure at least one field is being updated
          raise ArgumentError, 'At least one field must be provided to update' if project_data.empty?

          # Update project
          response = redmine_client.put("/projects/#{project_id}", { project: project_data })

          # PUT typically returns empty body on success (204), so fetch updated project
          if response.empty?
            get_response = redmine_client.get("/projects/#{project_id}")
            get_response['project'] || get_response
          else
            response['project'] || response
          end
        end
      end
    end
  end
end
