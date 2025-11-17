# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module CustomFields
      # Tool for updating an existing custom field in Redmine
      # Uses the Extended API plugin endpoint
      class UpdateCustomFieldTool < BaseTool
        def name
          'update_custom_field'
        end

        def description
          'Update an existing custom field in Redmine. Uses the Extended API plugin. ' \
            'Requires admin permissions. Can modify name, validators, visibility, and other settings.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              custom_field_id: {
                type: 'integer',
                description: 'Custom field ID to update (required)'
              },
              name: {
                type: 'string',
                description: 'Custom field name'
              },
              field_format: {
                type: 'string',
                description: 'Field format. Options: string, text, int, float, date, bool, ' \
                             'list, user, version, link, attachment'
              },
              is_required: {
                type: 'boolean',
                description: 'Whether the field is required'
              },
              is_for_all: {
                type: 'boolean',
                description: 'Whether the field is available for all projects'
              },
              default_value: {
                type: 'string',
                description: 'Default value for the field'
              },
              min_length: {
                type: 'integer',
                description: 'Minimum length for text fields'
              },
              max_length: {
                type: 'integer',
                description: 'Maximum length for text fields'
              },
              regexp: {
                type: 'string',
                description: 'Regular expression for validation'
              },
              multiple: {
                type: 'boolean',
                description: 'Allow multiple values (for list fields)'
              },
              visible: {
                type: 'boolean',
                description: 'Whether the field is visible'
              },
              searchable: {
                type: 'boolean',
                description: 'Whether the field is searchable'
              },
              description: {
                type: 'string',
                description: 'Description of the custom field'
              },
              editable: {
                type: 'boolean',
                description: 'Whether the field is editable'
              },
              tracker_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'Array of tracker IDs (for Issue custom fields)'
              },
              possible_values: {
                type: 'array',
                items: { type: 'string' },
                description: 'Possible values for list fields'
              },
              project_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'Array of project IDs (when is_for_all is false)'
              },
              role_ids: {
                type: 'array',
                items: { type: 'integer' },
                description: 'Array of role IDs that can see this field'
              }
            },
            required: %w[custom_field_id]
          }
        end

        def execute(params)
          validate_required_params(params, :custom_field_id)

          # Build custom field update data (only include provided fields)
          custom_field_data = {}
          custom_field_data[:name] = params[:name] if params[:name]
          custom_field_data[:field_format] = params[:field_format] if params[:field_format]
          custom_field_data[:is_required] = params[:is_required] if params.key?(:is_required)
          custom_field_data[:is_for_all] = params[:is_for_all] if params.key?(:is_for_all)
          custom_field_data[:default_value] = params[:default_value] if params[:default_value]
          custom_field_data[:min_length] = params[:min_length] if params[:min_length]
          custom_field_data[:max_length] = params[:max_length] if params[:max_length]
          custom_field_data[:regexp] = params[:regexp] if params[:regexp]
          custom_field_data[:multiple] = params[:multiple] if params.key?(:multiple)
          custom_field_data[:visible] = params[:visible] if params.key?(:visible)
          custom_field_data[:searchable] = params[:searchable] if params.key?(:searchable)
          custom_field_data[:description] = params[:description] if params[:description]
          custom_field_data[:editable] = params[:editable] if params.key?(:editable)
          custom_field_data[:tracker_ids] = params[:tracker_ids] if params[:tracker_ids]
          custom_field_data[:possible_values] = params[:possible_values] if params[:possible_values]
          custom_field_data[:project_ids] = params[:project_ids] if params[:project_ids]
          custom_field_data[:role_ids] = params[:role_ids] if params[:role_ids]

          # Update custom field using Extended API
          redmine_client.put(
            "/extended_api/custom_fields/#{params[:custom_field_id]}",
            { custom_field: custom_field_data }
          )
        end
      end
    end
  end
end
