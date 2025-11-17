# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Users
      # Tool for updating an existing user in Redmine
      class UpdateUserTool < BaseTool
        def name
          'update_user'
        end

        def description
          'Update an existing user in Redmine. Only provided fields will be updated. Requires admin privileges.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              id: {
                type: %w[string integer],
                description: 'User ID (numeric) or "current" for the authenticated API user - required'
              },
              login: {
                type: 'string',
                description: 'New user login (username)',
                minLength: 1
              },
              firstname: {
                type: 'string',
                description: 'New user first name',
                minLength: 1
              },
              lastname: {
                type: 'string',
                description: 'New user last name',
                minLength: 1
              },
              mail: {
                type: 'string',
                description: 'New user email address',
                format: 'email'
              },
              password: {
                type: 'string',
                description: 'New user password (min 8 characters)',
                minLength: 8
              },
              auth_source_id: {
                type: 'integer',
                description: 'Authentication source ID (for LDAP/external auth)'
              },
              mail_notification: {
                type: 'string',
                description: 'Email notification preference',
                enum: %w[all selected only_my_events only_assigned only_owner none]
              },
              must_change_passwd: {
                type: 'boolean',
                description: 'Force user to change password on next login'
              },
              admin: {
                type: 'boolean',
                description: 'Grant or revoke admin privileges'
              },
              status: {
                type: 'integer',
                description: 'User status: 1=Active, 2=Registered, 3=Locked'
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

          user_id = params[:id]

          # Build user update payload (only include fields that are provided)
          user_data = {}

          user_data[:login] = params[:login] if params[:login]
          user_data[:firstname] = params[:firstname] if params[:firstname]
          user_data[:lastname] = params[:lastname] if params[:lastname]
          user_data[:mail] = params[:mail] if params[:mail]
          user_data[:password] = params[:password] if params[:password]
          user_data[:auth_source_id] = params[:auth_source_id] if params[:auth_source_id]
          user_data[:mail_notification] = params[:mail_notification] if params[:mail_notification]
          user_data[:must_change_passwd] = params[:must_change_passwd] unless params[:must_change_passwd].nil?
          user_data[:admin] = params[:admin] unless params[:admin].nil?
          user_data[:status] = params[:status] if params[:status]
          user_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]

          # Ensure at least one field is being updated
          raise ArgumentError, 'At least one field must be provided to update' if user_data.empty?

          # Update user
          response = redmine_client.put("/users/#{user_id}", { user: user_data })

          # PUT typically returns empty body on success (204), so fetch updated user
          if response.empty?
            get_response = redmine_client.get("/users/#{user_id}")
            get_response['user'] || get_response
          else
            response['user'] || response
          end
        end
      end
    end
  end
end
