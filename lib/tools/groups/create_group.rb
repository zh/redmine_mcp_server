# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Groups
      # Tool for creating a new group in Redmine
      class CreateGroupTool < BaseTool
        def name
          'create_group'
        end

        def description
          'Create a new group in Redmine. Groups are used to organize users and manage permissions. ' \
          'Can optionally add initial members. Requires admin privileges.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              name: {
                type: 'string',
                description: 'Group name',
                minLength: 1
              },
              user_ids: {
                type: 'array',
                description: 'Array of user IDs to add as initial group members',
                items: {
                  type: 'integer'
                }
              }
            },
            required: ['name']
          }
        end

        def execute(params)
          validate_required_params(params, :name)

          # Build group payload
          group_data = {
            name: params[:name]
          }

          # Add optional fields
          group_data[:user_ids] = params[:user_ids] if params[:user_ids]

          # Create group
          response = redmine_client.post('/groups', { group: group_data })

          response['group'] || response
        end
      end
    end
  end
end
