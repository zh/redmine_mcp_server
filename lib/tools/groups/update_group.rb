# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Groups
      # Tool for updating an existing group in Redmine
      class UpdateGroupTool < BaseTool
        def name
          'update_group'
        end

        def description
          'Update an existing group in Redmine. Only provided fields will be updated. Requires admin privileges.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: 'integer',
                description: 'Group ID - required'
              },
              name: {
                type: 'string',
                description: 'New group name',
                minLength: 1
              }
            },
            required: ['id']
          }
        end

        def execute(params)
          validate_required_params(params, :id)

          group_id = params[:id]

          # Build group update payload (only include fields that are provided)
          group_data = {}

          group_data[:name] = params[:name] if params[:name]

          # Ensure at least one field is being updated
          raise ArgumentError, 'At least one field must be provided to update' if group_data.empty?

          # Update group
          response = redmine_client.put("/groups/#{group_id}", { group: group_data })

          # PUT typically returns empty body on success (204), so fetch updated group
          if response.empty?
            get_response = redmine_client.get("/groups/#{group_id}")
            get_response['group'] || get_response
          else
            response['group'] || response
          end
        end
      end
    end
  end
end
