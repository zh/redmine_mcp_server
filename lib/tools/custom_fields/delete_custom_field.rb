# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module CustomFields
      # Tool for deleting a custom field from Redmine
      # Uses the Extended API plugin endpoint
      class DeleteCustomFieldTool < BaseTool
        def name
          'delete_custom_field'
        end

        def description
          'Delete a custom field from Redmine. Uses the Extended API plugin. ' \
            'Requires admin permissions. Cannot delete custom fields that are in use.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              custom_field_id: {
                type: 'integer',
                description: 'Custom field ID to delete (required)'
              }
            },
            required: %w[custom_field_id]
          }
        end

        def execute(params)
          validate_required_params(params, :custom_field_id)

          # Delete custom field using Extended API
          redmine_client.delete("/extended_api/custom_fields/#{params[:custom_field_id]}")

          # Return success message
          { success: true, message: 'Custom field deleted successfully' }
        end
      end
    end
  end
end
