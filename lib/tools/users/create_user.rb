# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module Users
      # Tool for creating a new user in Redmine
      class CreateUserTool < BaseTool
        def name
          'create_user'
        end

        def description
          'Create a new user in Redmine. Requires admin privileges. Can optionally send account information ' \
          'to the user via email or generate a random password.'
        end

        def input_schema
          {
            type: 'object',
            properties: {
              login: {
                type: 'string',
                description: 'User login (username)',
                minLength: 1
              },
              firstname: {
                type: 'string',
                description: 'User first name',
                minLength: 1
              },
              lastname: {
                type: 'string',
                description: 'User last name',
                minLength: 1
              },
              mail: {
                type: 'string',
                description: 'User email address',
                format: 'email'
              },
              password: {
                type: 'string',
                description: 'User password (min 8 characters, leave empty to generate)',
                minLength: 8
              },
              auth_source_id: {
                type: 'integer',
                description: 'Authentication source ID (for LDAP/external auth)'
              },
              mail_notification: {
                type: 'string',
                description: 'Email notification preference',
                enum: %w[all selected only_my_events only_assigned only_owner none],
                default: 'only_my_events'
              },
              must_change_passwd: {
                type: 'boolean',
                description: 'Force user to change password on first login',
                default: false
              },
              generate_password: {
                type: 'boolean',
                description: 'Generate a random password for the user',
                default: false
              },
              send_information: {
                type: 'boolean',
                description: 'Send account information to user via email',
                default: false
              },
              admin: {
                type: 'boolean',
                description: 'Grant admin privileges to the user',
                default: false
              },
              custom_fields: {
                type: 'array',
                description: 'Custom field values for the user',
                items: {
                  type: 'object',
                  properties: {
                    id: { type: 'integer' },
                    value: { type: %w[string number boolean array] }
                  },
                  required: %w[id value]
                }
              }
            },
            required: %w[login firstname lastname mail]
          }
        end

        def execute(params)
          validate_required_params(params, :login, :firstname, :lastname, :mail)

          # Build user payload
          user_data = {
            login: params[:login],
            firstname: params[:firstname],
            lastname: params[:lastname],
            mail: params[:mail]
          }

          # Add optional fields
          user_data[:password] = params[:password] if params[:password]
          user_data[:auth_source_id] = params[:auth_source_id] if params[:auth_source_id]
          user_data[:mail_notification] = params[:mail_notification] if params[:mail_notification]
          user_data[:must_change_passwd] = params[:must_change_passwd] unless params[:must_change_passwd].nil?
          user_data[:generate_password] = params[:generate_password] unless params[:generate_password].nil?
          user_data[:admin] = params[:admin] unless params[:admin].nil?
          user_data[:custom_fields] = params[:custom_fields] if params[:custom_fields]

          # Prepare request payload
          payload = { user: user_data }
          payload[:send_information] = params[:send_information] unless params[:send_information].nil?

          # Create user
          response = redmine_client.post('/users', payload)

          response['user'] || response
        end
      end
    end
  end
end
