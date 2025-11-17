# frozen_string_literal: true

require_relative '../base_tool'

module RedmineMcpServer
  module Tools
    module CustomFields
      # Tool for listing custom fields from Redmine
      class ListCustomFieldsTool < BaseTool
        def name
          'list_custom_fields'
        end

        def description
          'List all custom fields in Redmine. Returns all field types (Issue, Project, User, etc.) ' \
          'with their configuration including field format, validators, and visibility settings.'
        end

        def input_schema
          {
            type: 'object',
            properties: {}
          }
        end

        def execute(_params)
          # Fetch all custom fields
          response = redmine_client.get('/custom_fields')

          {
            custom_fields: response['custom_fields'] || []
          }
        end
      end
    end
  end
end
